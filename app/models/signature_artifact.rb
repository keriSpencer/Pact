class SignatureArtifact < ApplicationRecord
  belongs_to :signature_request
  has_many :field_completions, class_name: "SignatureFieldCompletion", dependent: :restrict_with_error

  validates :signer_email, presence: true
  validates :artifact_type, presence: true
  validates :artifact_data, presence: true
  validates :capture_method, presence: true

  def self.find_or_create_for(signature_request:, signer_email:, artifact_type:, artifact_data:, capture_method: "typed", typed_text: nil, ip_address: nil, user_agent: nil)
    existing = signature_request.signature_artifacts.find_by(
      signer_email: signer_email,
      artifact_type: artifact_type
    )

    if existing
      existing.update!(
        artifact_data: artifact_data,
        typed_text: typed_text,
        capture_method: capture_method,
        ip_address: ip_address,
        user_agent: user_agent
      )
      existing
    else
      signature_request.signature_artifacts.create!(
        signer_email: signer_email,
        artifact_type: artifact_type,
        artifact_data: artifact_data,
        typed_text: typed_text,
        capture_method: capture_method,
        ip_address: ip_address,
        user_agent: user_agent
      )
    end
  end
end
