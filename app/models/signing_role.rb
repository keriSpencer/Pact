class SigningRole < ApplicationRecord
  belongs_to :signing_envelope
  belongs_to :contact, optional: true

  has_one :signature_request, dependent: :nullify
  has_many :signature_fields, dependent: :nullify

  COLORS = %w[#2563EB #DC2626 #059669 #D97706 #7C3AED #DB2777 #0891B2 #EA580C].freeze

  validates :label, presence: true
  validates :label, uniqueness: { scope: :signing_envelope_id }
  validates :signer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
            unless: -> { signing_envelope&.draft? || is_self_signer }

  scope :in_order, -> { order(:signing_order) }

  def display_name
    signer_name.presence || label
  end

  def display_email
    is_self_signer ? signing_envelope.requester.email : signer_email
  end

  def can_sign_now?
    signing_envelope.can_signer_sign?(self)
  end

  def signed?
    signature_request&.signed?
  end

  def status_text
    return "Self-signed" if is_self_signer && signed?
    return "Signed" if signed?
    return "Waiting" if signing_envelope.sequential? && !can_sign_now?
    signature_request&.status&.humanize || "Pending"
  end
end
