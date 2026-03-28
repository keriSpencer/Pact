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
  before_create :generate_schema_name

  scope :active, -> { where(active: true) }

  PLAN_LIMITS = { "free" => 3, "starter" => 10, "pro" => Float::INFINITY }.freeze

  def document_limit
    PLAN_LIMITS[plan] || 3
  end

  def documents_used_this_month
    documents.where("created_at >= ?", Time.current.beginning_of_month).count
  end

  def can_create_document?
    documents_used_this_month < document_limit
  end

  def documents_remaining_this_month
    limit = document_limit
    return Float::INFINITY if limit == Float::INFINITY
    [limit - documents_used_this_month, 0].max
  end

  def free_plan?
    plan == "free"
  end

  def paid_plan?
    plan.in?(%w[starter pro])
  end

  def pro_plan?
    plan == "pro"
  end

  def subscription_active?
    subscription_status.in?(%w[active trialing])
  end

  def plan_display_name
    plan.to_s.capitalize
  end

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

  def generate_schema_name
    self.schema_name ||= "tenant_#{slug.gsub('-', '_')}"
  end

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
