class DocumentShare < ApplicationRecord
  belongs_to :document
  belongs_to :user, optional: true
  belongs_to :contact, optional: true
  belongs_to :shared_by, class_name: "User"

  enum :permission_level, { view: 0, edit: 1, admin: 2, sign_only: 3 }

  validates :permission_level, presence: true
  validates :user_id, uniqueness: { scope: :document_id, message: "already has access to this document" }, allow_nil: true
  validates :contact_id, uniqueness: { scope: :document_id, message: "already has access to this document" }, allow_nil: true
  validate :recipient_present
  validate :contact_permission_restrictions

  before_validation :generate_share_token, if: -> { contact_id.present? && share_token.blank? }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !expired?
  end

  def record_access!
    now = Time.current
    update_columns(
      accessed_at: now,
      first_access_at: first_access_at || now,
      access_count: access_count + 1
    )
  end

  def recipient
    user || contact
  end

  def recipient_name
    if user.present?
      user.full_name
    elsif contact.present?
      contact.full_name
    else
      "Unknown"
    end
  end

  def recipient_email
    if user.present?
      user.email
    elsif contact.present?
      contact.email
    else
      nil
    end
  end

  def external?
    contact_id.present? && user_id.blank?
  end

  def share_url
    return nil unless share_token.present?
    Rails.application.routes.url_helpers.shared_document_url(share_token, host: default_host)
  end

  def can_view?
    active? && (view? || edit? || admin? || sign_only?)
  end

  def can_sign?
    active? && sign_only?
  end

  private

  def generate_share_token
    self.share_token = SecureRandom.urlsafe_base64(32)
  end

  def recipient_present
    if user_id.blank? && contact_id.blank?
      errors.add(:base, "Must share with either a user or a contact")
    end
  end

  def contact_permission_restrictions
    if contact_id.present? && (edit? || admin?)
      errors.add(:permission_level, "contacts can only have view or sign_only access")
    end
  end

  def default_host
    Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
  end
end
