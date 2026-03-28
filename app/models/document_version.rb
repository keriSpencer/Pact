class DocumentVersion < ApplicationRecord
  belongs_to :document
  belongs_to :signature_request, optional: true
  belongs_to :parent_version, class_name: "DocumentVersion", optional: true

  has_one :audit_certificate, class_name: "DocumentVersion",
          foreign_key: :parent_version_id, dependent: :destroy

  has_one_attached :file

  enum :version_type, {
    original: "original",
    signed: "signed",
    audit_certificate: "audit_certificate"
  }

  before_save :compute_checksum, if: -> { file.attached? && checksum.blank? }

  validates :version_type, presence: true
  validates :signature_request_id, uniqueness: true, allow_nil: true

  scope :originals, -> { where(version_type: "original") }
  scope :signed_versions, -> { where(version_type: "signed") }
  scope :audit_certificates, -> { where(version_type: "audit_certificate") }
  scope :in_order, -> { order(created_at: :desc) }

  def display_label
    if label.present?
      label
    elsif signed? && signature_request.present?
      "Signed by #{signature_request.signer_display_name}"
    elsif audit_certificate?
      "Audit Certificate"
    elsif original?
      "Original"
    else
      "Version #{id}"
    end
  end

  def formatted_date
    created_at.strftime("%b %d, %Y at %l:%M %p")
  end

  private

  def compute_checksum
    self.checksum = Digest::SHA256.hexdigest(file.download)
  rescue ActiveStorage::FileNotFoundError
    nil
  end
end
