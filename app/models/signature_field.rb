class SignatureField < ApplicationRecord
  belongs_to :signature_request
  has_one :completion, class_name: "SignatureFieldCompletion", dependent: :destroy

  FIELD_TYPES = %w[signature initials date text name email company title checkbox].freeze

  validates :field_type, presence: true, inclusion: { in: FIELD_TYPES }
  validates :page_number, presence: true, numericality: { greater_than: 0 }
  validates :x_percent, :y_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :width_percent, :height_percent, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :required_fields, -> { where(required: true) }
  scope :optional_fields, -> { where(required: false) }
  scope :by_position, -> { order(:position) }

  def completed?
    completion.present?
  end

  def complete!(artifact:, signer_email:, ip_address: nil, user_agent: nil)
    return false if completed?

    create_completion!(
      signature_artifact: artifact,
      signer_email: signer_email,
      ip_address: ip_address,
      user_agent: user_agent,
      completed_at: Time.current
    )

    signature_request.recalculate_completion!
    true
  end

  def reset!
    return false unless completed?
    completion.destroy!
    signature_request.recalculate_completion!
    true
  end

  def placement_data
    {
      page: page_number,
      x: x_percent,
      y: y_percent,
      width: width_percent,
      height: height_percent,
      type: field_type,
      required: required
    }
  end

  def stamp_data
    return nil unless completed?
    {
      page: page_number,
      x: x_percent,
      y: y_percent,
      width: width_percent,
      height: height_percent,
      type: field_type,
      data: completion.signature_artifact.artifact_data
    }
  end

  def label
    self[:label].presence || field_type.humanize
  end
end
