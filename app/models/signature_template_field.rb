class SignatureTemplateField < ApplicationRecord
  belongs_to :signature_template

  validates :field_type, presence: true, inclusion: { in: SignatureField::FIELD_TYPES }
  validates :page_number, presence: true, numericality: { greater_than: 0 }
  validates :x_percent, :y_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :width_percent, :height_percent, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
