class SigningEnvelope < ApplicationRecord
  belongs_to :document
  belongs_to :requester, class_name: "User"
  belongs_to :voided_by, class_name: "User", optional: true

  has_many :signing_roles, dependent: :destroy
  has_many :signature_requests, dependent: :destroy

  accepts_nested_attributes_for :signing_roles, allow_destroy: true

  enum :signing_mode, { parallel: 0, sequential: 1 }
  enum :status, { draft: 0, active: 1, completed: 2, voided: 3, cancelled: 4 }

  validates :document, presence: true
  validates :requester, presence: true

  def all_signers_completed?
    return false if signing_roles.empty?
    signing_roles.each do |role|
      sr = role.signature_request
      return false unless sr&.signed?
    end
    true
  end

  def completion_progress
    total = signing_roles.count
    return 0 if total == 0
    signed = signing_roles.joins(:signature_request).where(signature_requests: { status: :signed }).count
    ((signed.to_f / total) * 100).round
  end

  def check_completion!
    return unless active?
    if all_signers_completed?
      update!(status: :completed, completed_at: Time.current)
      GenerateMultiSignerPdfJob.perform_later(id)
      SignatureRequestMailer.all_signers_completed(self).deliver_later
    end
  end

  def signed_version
    # Find the document version created when this envelope completed
    document.versions.where(version_type: "signed")
            .where("created_at >= ? AND created_at <= ?", completed_at - 1.minute, completed_at + 5.minutes)
            .order(created_at: :desc)
            .first
  end

  def next_signing_order
    return nil unless sequential?
    signing_roles.left_joins(:signature_request)
      .where("signature_requests.status IS NULL OR signature_requests.status != ?", SignatureRequest.statuses[:signed])
      .order(:signing_order)
      .first
      &.signing_order
  end

  def can_signer_sign?(signing_role)
    return false unless active?
    return true if parallel?
    signing_role.signing_order == next_signing_order
  end

  def activate!
    return false unless draft?

    transaction do
      signing_roles.where(is_self_signer: false).each do |role|
        next if role.signer_email.blank?

        sr = signature_requests.create!(
          document: document,
          requester: requester,
          signer_email: role.signer_email,
          signer_name: role.signer_name,
          contact: role.contact,
          status: :pending,
          signing_role: role,
          signing_envelope: self
        )

        # Move fields assigned to this role onto this request
        SignatureField.where(signing_role: role).update_all(signature_request_id: sr.id)
      end

      # Handle self-signer roles
      signing_roles.where(is_self_signer: true).each do |role|
        sr = signature_requests.create!(
          document: document,
          requester: requester,
          signer_email: requester.email,
          signer_name: requester.full_name,
          status: :signed,
          signed_at: Time.current,
          signing_role: role,
          signing_envelope: self
        )

        SignatureField.where(signing_role: role).update_all(signature_request_id: sr.id)
      end

      update!(status: :active)
      send_invitations!
    end
    true
  end

  def send_invitations!
    signing_roles.where(is_self_signer: false).each do |role|
      sr = role.signature_request
      next unless sr

      if sequential? && role.signing_order != 0
        next # Don't send yet — they'll be notified when it's their turn
      end

      sr.send_signature_request!
    end
  end

  def send_next_signer_invitation!
    return unless sequential? && active?

    next_order = next_signing_order
    return unless next_order

    next_role = signing_roles.find_by(signing_order: next_order)
    return unless next_role

    sr = next_role.signature_request
    sr&.send_signature_request!
  end

  def void!(user)
    return false unless active? || draft?

    transaction do
      signature_requests.where.not(status: [:signed, :voided]).each do |sr|
        sr.update!(status: :cancelled)
      end
      update!(status: :voided, voided_at: Time.current, voided_by: user)
    end
    true
  end
end
