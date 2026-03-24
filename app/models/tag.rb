class Tag < ApplicationRecord
  include TenantIsolated

  belongs_to :organization
  has_many :contact_tags, dependent: :destroy
  has_many :contacts, through: :contact_tags

  validates :name, presence: true, uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :color, presence: true

  scope :ordered, -> { order(:name) }

  COLORS = %w[blue green amber red purple pink teal indigo gray orange].freeze

  def bg_class
    {
      "blue" => "bg-blue-100",
      "green" => "bg-green-100",
      "amber" => "bg-amber-100",
      "red" => "bg-red-100",
      "purple" => "bg-purple-100",
      "pink" => "bg-pink-100",
      "teal" => "bg-teal-100",
      "indigo" => "bg-indigo-100",
      "gray" => "bg-gray-100",
      "orange" => "bg-orange-100"
    }[color] || "bg-gray-100"
  end

  def text_class
    {
      "blue" => "text-blue-700",
      "green" => "text-green-700",
      "amber" => "text-amber-700",
      "red" => "text-red-700",
      "purple" => "text-purple-700",
      "pink" => "text-pink-700",
      "teal" => "text-teal-700",
      "indigo" => "text-indigo-700",
      "gray" => "text-gray-700",
      "orange" => "text-orange-700"
    }[color] || "text-gray-700"
  end
end
