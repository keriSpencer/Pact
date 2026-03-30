class SignatureRequest < ApplicationRecord
  belongs_to :document
  belongs_to :requester, class_name: "User"
  belongs_to :signer, class_name: "User", optional: true
  belongs_to :voided_by, class_name: "User", optional: true
  belongs_to :contact, optional: true
  belongs_to :signing_envelope, optional: true
  belongs_to :signing_role, optional: true

  has_many :signature_fields, dependent: :destroy
  has_many :signature_artifacts, dependent: :destroy
  has_one :signed_version, class_name: "DocumentVersion", dependent: :nullify

  accepts_nested_attributes_for :signature_fields, allow_destroy: true, reject_if: :all_blank

  enum :status, {
    pending: 0,
    sent: 1,
    viewed: 2,
    signed: 3,
    declined: 4,
    expired: 5,
    cancelled: 6,
    voided: 7,
    draft: 8
  }

  validates :signer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: :draft?
  validates :signature_token, presence: true, uniqueness: true

  before_validation :generate_signature_token, on: :create
  before_validation :auto_match_contact

  scope :stale_drafts, -> { where(status: :draft).where("updated_at < ?", 7.days.ago) }
  scope :active_requests, -> { where(status: [:pending, :sent, :viewed]) }
  scope :completed, -> { where(status: [:signed, :declined, :cancelled, :voided]) }

  def can_sign?
    pending? || sent? || viewed?
  end

  def uses_multi_field?
    signature_fields.any?
  end

  def all_required_fields_completed?
    return true unless uses_multi_field?
    # Date fields are completed at finalize time, so exclude them from the check
    signature_fields.where(required: true).where.not(field_type: "date").all? { |f| f.completed? }
  end

  def completion_progress
    required = signature_fields.where(required: true)
    return 100 if required.empty?
    completed = required.select(&:completed?)
    ((completed.count.to_f / required.count) * 100).round
  end

  def next_incomplete_field
    signature_fields.order(:position).detect { |f| f.required? && !f.completed? }
  end

  def recalculate_completion!
    required = signature_fields.where(required: true).count
    completed = signature_fields.joins(:completion).where(required: true).count
    update_columns(
      fields_required_count: required,
      fields_completed_count: completed
    )
  end

  def finalize_signing!(ip_address: nil, user_agent: nil)
    return false unless can_sign?
    return false if uses_multi_field? && !all_required_fields_completed?

    auto_complete_date_fields!

    update!(
      status: :signed,
      signed_at: Time.current,
      ip_address: ip_address,
      user_agent: user_agent
    )

    if signing_envelope.present?
      # Multi-signer: envelope coordinates PDF generation and notifications
      signing_envelope.check_completion!
      signing_envelope.send_next_signer_invitation! if signing_envelope.sequential?
      # Notify requester of this individual signing
      SignatureRequestMailer.signature_completed(self).deliver_later
      SignatureRequestMailer.signer_copy(self).deliver_later
    else
      # Legacy single-signer: generate PDF and notify immediately
      GenerateSignedPdfJob.perform_later(id) if document.pdf?
      GenerateAuditCertificateJob.perform_later(id)
      SignatureRequestMailer.signature_completed(self).deliver_later
      SignatureRequestMailer.signer_copy(self).deliver_later
    end
    send_signed_push_notification
    true
  end

  def signed_view_url
    # Signer can view their signed document via the signing token
    Rails.application.routes.url_helpers.signature_url(signature_token, host: default_host)
  end

  def void!(user)
    return false unless can_sign?
    update!(
      status: :voided,
      voided_at: Time.current,
      voided_by: user
    )
  end

  def sign!(signature_data:, ip_address: nil, user_agent: nil)
    return false unless can_sign?

    update!(
      status: :signed,
      signed_at: Time.current,
      signature_data: signature_data,
      ip_address: ip_address,
      user_agent: user_agent
    )

    GenerateSignedPdfJob.perform_later(id) if document.pdf?
    SignatureRequestMailer.signature_completed(self).deliver_later
    send_signed_push_notification
    true
  end

  def decline!(reason: nil, ip_address: nil, user_agent: nil)
    return false unless can_sign?
    update!(
      status: :declined,
      decline_reason: reason,
      ip_address: ip_address,
      user_agent: user_agent
    )
    SignatureRequestMailer.signature_declined(self).deliver_later
    true
  end

  def cancel!
    return false unless can_sign?
    update!(status: :cancelled)
  end

  def mark_as_viewed!
    return if viewed? || signed? || declined?
    update!(status: :viewed, viewed_at: Time.current) if sent? || pending?
  end

  def send_signature_request!
    return false if signed? || declined? || cancelled? || voided?
    update!(status: :sent, sent_at: Time.current)
    SignatureRequestMailer.signature_request(self).deliver_later
    true
  end

  def signer_display_name
    signer_name.presence || signer_email
  end

  def status_color_class
    case status
    when "signed" then "bg-green-100 text-green-800"
    when "pending", "sent" then "bg-yellow-100 text-yellow-800"
    when "viewed" then "bg-blue-100 text-blue-800"
    when "declined" then "bg-red-100 text-red-800"
    when "expired", "cancelled", "voided" then "bg-gray-100 text-gray-800"
    when "draft" then "bg-purple-100 text-purple-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def signature_url
    Rails.application.routes.url_helpers.signature_url(signature_token, host: default_host)
  end

  def generate_signed_version!
    return unless signed? && document.pdf? && document.file.attached?

    stamped_pdf = PdfStampingService.new(self).stamp!
    return unless stamped_pdf

    version = document.versions.create!(
      version_type: "signed",
      label: "Signed by #{signer_display_name}",
      signature_request: self
    )
    version.file.attach(
      io: StringIO.new(stamped_pdf),
      filename: "signed_#{document.file.filename}",
      content_type: "application/pdf"
    )
    version
  end

  def auto_complete_date_fields!
    signature_fields.where(field_type: "date").each do |field|
      next if field.completed?
      artifact = SignatureArtifact.find_or_create_for(
        signature_request: self,
        signer_email: signer_email,
        artifact_type: "date",
        artifact_data: Time.current.strftime("%B %d, %Y at %l:%M %p"),
        capture_method: "auto"
      )
      field.complete!(artifact: artifact, signer_email: signer_email)
    end
  end

  private

  def generate_signature_token
    self.signature_token = SecureRandom.urlsafe_base64(32) if signature_token.blank?
  end

  def auto_match_contact
    return unless signer_email.present? && contact_id.blank? && document&.organization_id.present?
    matched = Contact.where(organization_id: document.organization_id, email: signer_email).first
    if matched
      self.contact = matched
      self.auto_matched = true
    end
  end

  def send_signed_push_notification
    return unless requester.push_devices.any?

    notification = ApplicationPushNotification
      .with_data(path: "/documents/#{document.id}")
      .new(title: "Document signed!", body: "#{signer_display_name} signed your doc!")

    notification.deliver_later_to(requester.push_devices)
  end

  def default_host
    opts = Rails.application.config.action_mailer.default_url_options || {}
    host = opts[:host] || "localhost"
    port = opts[:port]
    port ? "#{host}:#{port}" : host
  end
end
