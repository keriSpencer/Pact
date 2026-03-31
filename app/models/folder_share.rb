class FolderShare < ApplicationRecord
  belongs_to :folder
  belongs_to :shared_by, class_name: "User"
  belongs_to :user, optional: true

  enum :permission_level, { view: 0, edit: 1 }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :folder_id, message: "already has access to this folder" }

  before_validation :normalize_email
  before_validation :resolve_user
  before_validation :generate_share_token, if: -> { share_token.blank? }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !expired?
  end

  def internal?
    user_id.present?
  end

  def external?
    user_id.blank?
  end

  def record_access!
    now = Time.current
    update_columns(
      accessed_at: now,
      first_access_at: first_access_at || now,
      access_count: access_count + 1
    )
  end

  def share_url
    Rails.application.routes.url_helpers.shared_folder_url(share_token, host: default_host)
  end

  def recipient_name
    user&.full_name || email
  end

  private

  def normalize_email
    self.email = email&.strip&.downcase
  end

  def resolve_user
    return if email.blank?
    self.user = User.find_by(email: email)
  end

  def generate_share_token
    self.share_token = SecureRandom.urlsafe_base64(32)
  end

  def default_host
    Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
  end
end
