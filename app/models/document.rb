class Document < ApplicationRecord
  include TenantIsolated

  belongs_to :organization
  belongs_to :folder, optional: true
  belongs_to :user
  belongs_to :contact, optional: true

  has_many :versions, class_name: "DocumentVersion", dependent: :destroy
  has_many :document_shares, dependent: :destroy
  has_many :signature_requests, dependent: :destroy
  has_many :signing_envelopes, dependent: :destroy
  has_many :signature_templates, dependent: :destroy

  has_one_attached :file

  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :file, presence: true, on: :create

  enum :visibility, { doc_private: 0, organization: 1, doc_public: 2 }
  enum :status, { active: 0, archived: 1, deleted: 2 }

  before_validation :extract_file_metadata, on: :create
  before_create :calculate_file_hash

  scope :for_organization, ->(org) { where(organization: org) }

  scope :visible_to, ->(user) {
    where(organization_id: user.organization_id)
      .where(
        "(documents.visibility = ? AND documents.user_id = ?) OR documents.visibility IN (?, ?)",
        visibilities[:doc_private], user.id,
        visibilities[:organization], visibilities[:doc_public]
      ).distinct
  }

  def file_extension
    return nil unless file.attached?
    File.extname(file.filename.to_s).downcase
  end

  def file_type_category
    case file_extension
    when ".pdf" then "pdf"
    when ".doc", ".docx" then "document"
    when ".xls", ".xlsx", ".csv" then "spreadsheet"
    when ".ppt", ".pptx" then "presentation"
    when ".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg" then "image"
    when ".txt" then "text"
    else "file"
    end
  end

  def image?
    content_type&.start_with?("image/") || %w[.jpg .jpeg .png .gif .webp .svg].include?(file_extension)
  end

  def pdf?
    content_type == "application/pdf" || file_extension == ".pdf"
  end

  def formatted_file_size
    return "Unknown" unless file_size
    units = ["B", "KB", "MB", "GB"]
    size = file_size.to_f
    unit_index = 0
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end
    "#{size.round(1)} #{units[unit_index]}"
  end

  def can_access?(user)
    return false unless user.organization_id == organization_id
    return true if self.user == user
    return true if user.can_manage_users?
    case visibility
    when "doc_public", "organization" then true
    when "doc_private" then false
    else false
    end
  end

  def has_signed_requests?
    signature_requests.where(status: :signed).exists?
  end

  # Safe deletion: archive documents with signed versions instead of destroying
  def safe_destroy!
    if has_signed_requests?
      # Archive instead of delete — preserve signed versions for legal compliance
      update!(status: :archived, folder_id: nil)
      false # indicates it was archived, not deleted
    else
      destroy
      true # indicates it was actually deleted
    end
  end

  def has_signed_version?
    versions.where(version_type: "signed").exists?
  end

  def latest_signed_version
    versions.where(version_type: "signed").order(created_at: :desc).first
  end

  def display_file
    latest_signed_version&.file || file
  end

  def derived_status
    if signature_requests.where(status: :signed).exists?
      :signed
    elsif signature_requests.where(status: [:pending, :sent, :viewed]).exists?
      :pending_signature
    elsif document_shares.active.exists?
      :shared
    else
      :draft
    end
  end

  def derived_status_display
    case derived_status
    when :signed then "Signed"
    when :pending_signature then "Pending Signature"
    when :shared then "Shared"
    else "Draft"
    end
  end

  def verify_integrity!
    return true unless file.attached? && file_hash.present?
    current_hash = Digest::SHA256.hexdigest(file.download)
    current_hash == file_hash
  end

  private

  def calculate_file_hash
    return unless file.attached?
    self.file_hash = Digest::SHA256.hexdigest(file.download)
  rescue => e
    Rails.logger.error "Failed to calculate file hash: #{e.message}"
  end

  def extract_file_metadata
    return unless file.attached?
    self.file_size = file.byte_size
    self.content_type = file.content_type
    self.name = file.filename.to_s if name.blank?
  end
end
