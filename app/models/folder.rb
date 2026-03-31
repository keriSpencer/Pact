class Folder < ApplicationRecord
  include TenantIsolated

  belongs_to :organization
  belongs_to :parent, class_name: "Folder", optional: true
  belongs_to :user

  has_many :subfolders, class_name: "Folder", foreign_key: "parent_id", dependent: :destroy
  has_many :documents, dependent: :nullify
  has_many :folder_shares, dependent: :destroy

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

  # Returns own folders + cross-organization shared folders
  def self.visible_to_with_shared(user)
    own = visible_to(user).to_a
    shared_folder_ids = FolderShare.where(user_id: user.id).active.pluck(:folder_id)
    shared_from_other_orgs = shared_folder_ids - own.map(&:id)
    if shared_from_other_orgs.any?
      cross_org = with_public_search_path { unscoped.where(deleted_at: nil, id: shared_from_other_orgs).to_a }
      own + cross_org
    else
      own
    end
  end

  def self.with_public_search_path
    conn = ActiveRecord::Base.connection
    return yield unless conn.adapter_name.downcase.include?("postgresql")
    old_path = conn.execute("SHOW search_path").first["search_path"]
    conn.execute("SET search_path TO public")
    result = yield
    conn.execute("SET search_path TO #{old_path}")
    result
  end

  # Find a folder by id, checking cross-org if needed for shared access
  def self.find_shared(id, user)
    folder = find_by(id: id)
    return folder if folder
    # Check cross-org: find folder and walk ancestors to verify share access
    with_public_search_path do
      folder = unscoped.where(deleted_at: nil).find_by(id: id)
      return nil unless folder
      # Check if this folder or any ancestor is shared with the user
      current = folder
      while current
        return folder if FolderShare.where(folder_id: current.id, user_id: user.id).active.exists?
        current = current.parent_id ? unscoped.where(deleted_at: nil).find_by(id: current.parent_id) : nil
      end
      nil
    end
  end

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
    return true if folder_shares.where(user_id: user.id).active.exists?
    return true if shared_via_ancestor?(user)
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

  def shared_with?(user)
    folder_shares.where(user_id: user.id).active.exists?
  end

  def shared_by_for(user)
    share = folder_shares.where(user_id: user.id).active.first
    share&.shared_by
  end

  # Check if an ancestor folder was shared with this user
  def shared_via_ancestor?(user)
    current = parent
    while current
      return true if current.folder_shares.where(user_id: user.id).active.exists?
      current = current.parent
    end
    false
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
