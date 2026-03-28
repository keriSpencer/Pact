class User < ApplicationRecord
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable

  enum :role, { member: 0, admin: 2 }, default: :member

  belongs_to :organization

  # Soft delete: exclude deleted users by default
  default_scope { where(deleted_at: nil) }
  scope :with_deleted, -> { unscope(where: :deleted_at) }
  scope :only_deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
  scope :active, -> { where(deleted_at: nil) }
  scope :in_organization, ->(org) { where(organization: org) }

  has_many :contact_assignments, dependent: :nullify
  has_many :assigned_contacts, through: :contact_assignments, source: :contact
  has_many :contact_notes, dependent: :nullify
  has_many :folders, dependent: :destroy
  has_many :documents, dependent: :destroy

  after_update :invalidate_caches
  after_destroy :invalidate_caches

  validates :first_name, :last_name, presence: true, if: :profile_complete?
  validates :phone, format: { with: /\A[\+]?[1-9][\d\s\-\(\)]*\z/, message: "Invalid phone format" }, allow_blank: true
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }, allow_blank: true

  def full_name
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name}".strip
    else
      email
    end
  end

  def display_name
    full_name
  end

  def display_name_with_email
    if first_name.present? && last_name.present?
      "#{full_name} (#{email})"
    else
      email
    end
  end

  def initials
    if first_name.present? && last_name.present?
      "#{first_name.first}#{last_name.first}".upcase
    else
      email.first.upcase
    end
  end

  # Authorization helpers
  def can_manage_users?
    admin?
  end

  def can_invite_users?
    admin?
  end

  def can_view_all_contacts?
    admin?
  end

  def can_manage_contact?(contact)
    return false unless contact.organization_id == organization_id
    return true if admin?
    return true if contact.assigned_users.include?(self)
    false
  end

  def permissions_cache
    Rails.cache.fetch("user_#{id}_permissions", expires_in: 30.minutes) do
      {
        can_manage_users: can_manage_users?,
        can_invite_users: can_invite_users?,
        can_view_all_contacts: can_view_all_contacts?
      }
    end
  end

  def can_delete_user?(user)
    return false unless user.organization_id == organization_id
    return false if user == self
    return true if admin? && !user.admin?
    false
  end

  def can_restore_user?(user)
    return false unless user.organization_id == organization_id
    return false unless user.deleted?
    return true if admin?
    false
  end

  def can_change_user_role?(user)
    return false unless user.organization_id == organization_id
    return false if user == self
    return true if admin? && !user.admin?
    false
  end

  def colleagues
    organization.users.where.not(id: id)
  end

  def notification_enabled?(type = nil)
    email_notifications
  end

  # Soft delete methods
  def soft_delete!
    update_column(:deleted_at, Time.current)
  end

  def restore!
    update_column(:deleted_at, nil)
  end

  def deleted?
    deleted_at.present?
  end

  def active_for_authentication?
    super && !deleted?
  end

  def inactive_message
    deleted? ? :account_deleted : super
  end

  private

  def profile_complete?
    first_name.present? || last_name.present?
  end

  def invalidate_caches
    Rails.cache.delete("user_#{id}_permissions")
  end
end
