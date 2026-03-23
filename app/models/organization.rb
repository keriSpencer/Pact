class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :folders, dependent: :destroy
  has_many :documents, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }

  before_validation :generate_slug, on: :create

  scope :active, -> { where(active: true) }

  def admins
    users.where(role: :admin)
  end

  def primary_admin
    admins.order(:created_at).first
  end

  def member_count
    users.count
  end

  private

  def generate_slug
    return if slug.present?
    base_slug = name.to_s.parameterize
    unique_slug = base_slug
    counter = 1
    while Organization.exists?(slug: unique_slug)
      unique_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    self.slug = unique_slug
  end
end
