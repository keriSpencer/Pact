class Folder < ApplicationRecord
  belongs_to :organization
  belongs_to :parent, class_name: "Folder", optional: true
  belongs_to :user

  has_many :subfolders, class_name: "Folder", foreign_key: "parent_id", dependent: :destroy
  has_many :documents, dependent: :nullify

  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :path, presence: true, uniqueness: { scope: :organization_id }

  enum :visibility, { folder_private: 0, organization: 1, folder_public: 2 }

  before_validation :generate_path, if: -> { name_changed? || new_record? }

  # Soft delete
  default_scope { where(deleted_at: nil) }
  scope :with_deleted, -> { unscope(where: :deleted_at) }
  scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }

  scope :root_folders, -> { where(parent_id: nil) }
  scope :for_organization, ->(org) { where(organization: org) }

  scope :visible_to, ->(user) {
    where(organization_id: user.organization_id)
      .where(
        "(visibility = ? AND user_id = ?) OR visibility IN (?, ?)",
        visibilities[:folder_private], user.id,
        visibilities[:organization], visibilities[:folder_public]
      )
  }

  def destroy
    update(deleted_at: Time.current)
    # Unfile documents instead of deleting them
    documents.update_all(folder_id: nil)
    # Soft delete subfolders too
    subfolders.each(&:destroy)
  end

  def restore!
    update(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end

  def has_contents?
    documents.any? || subfolders.any?
  end

  def contents_summary
    parts = []
    doc_count = documents.count
    sub_count = subfolders.count
    parts << "#{doc_count} #{'document'.pluralize(doc_count)}" if doc_count > 0
    parts << "#{sub_count} #{'subfolder'.pluralize(sub_count)}" if sub_count > 0
    parts.join(" and ")
  end

  def root?
    parent_id.nil?
  end

  def full_path
    return name if root?
    "#{parent.full_path}/#{name}"
  end

  def breadcrumbs
    return [self] if root?
    parent.breadcrumbs + [self]
  end

  def can_access?(user)
    return false unless user.organization_id == organization_id
    case visibility
    when "folder_private"
      self.user == user
    when "organization", "folder_public"
      true
    else
      false
    end
  end

  def document_count
    documents.where(status: :active).count
  end

  def subfolder_count
    subfolders.count
  end

  private

  def generate_path
    self.path = root? ? "/#{name}" : "#{parent.path}/#{name}"
  end
end
