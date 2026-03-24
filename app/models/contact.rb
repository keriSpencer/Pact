class Contact < ApplicationRecord
  include TenantIsolated

  belongs_to :organization
  has_many :contact_assignments, dependent: :destroy
  has_many :assigned_users, through: :contact_assignments, source: :user
  has_many :contact_notes, dependent: :destroy
  has_many :contact_tags, dependent: :destroy
  has_many :tags, through: :contact_tags
  has_many :document_shares, dependent: :destroy
  has_many :signature_requests, dependent: :nullify

  validates :first_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :organization_id, case_sensitive: false, conditions: -> { where(deleted_at: nil) } }
  validates :linkedin_url, format: { with: %r{\Ahttps?://(www\.)?linkedin\.com/in/.+\z}i, message: "must be a LinkedIn profile URL" }, allow_blank: true

  scope :for_organization, ->(org) { where(organization: org) }
  scope :unassigned, -> { left_joins(:contact_assignments).where(contact_assignments: { id: nil }) }
  scope :assigned, -> { joins(:contact_assignments).distinct }

  # Soft delete
  default_scope { where(deleted_at: nil) }
  scope :deleted, -> { unscoped.where.not(deleted_at: nil) }
  scope :with_deleted, -> { unscoped }

  def destroy
    update(deleted_at: Time.current)
  end

  def restore!
    update(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def name
    full_name
  end

  def linkedin_display
    return nil if linkedin_url.blank?
    match = linkedin_url.match(%r{linkedin\.com(/in/[^/?#]+)})
    match ? match[1] : linkedin_url
  end

  def unassigned?
    assigned_users.empty?
  end
end
