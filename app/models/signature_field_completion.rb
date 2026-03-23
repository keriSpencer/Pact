class SignatureFieldCompletion < ApplicationRecord
  belongs_to :signature_field
  belongs_to :signature_artifact

  validates :signer_email, presence: true
  validates :completed_at, presence: true
  validates :signature_field_id, uniqueness: true
end
