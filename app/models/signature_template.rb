class SignatureTemplate < ApplicationRecord
  belongs_to :document
  belongs_to :user
  belongs_to :organization

  has_many :template_fields, class_name: "SignatureTemplateField", dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :document_id }

  scope :by_recent, -> { order(last_used_at: :desc, created_at: :desc) }

  def increment_usage!
    update!(use_count: use_count + 1, last_used_at: Time.current)
  end

  def fields_as_json
    template_fields.order(:position).map do |tf|
      {
        page_number: tf.page_number,
        x_percent: tf.x_percent,
        y_percent: tf.y_percent,
        width_percent: tf.width_percent,
        height_percent: tf.height_percent,
        field_type: tf.field_type,
        label: tf.label,
        required: tf.required,
        position: tf.position,
        role_label: tf.role_label
      }
    end
  end
end
