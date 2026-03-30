class AddMultiSignerToSignatureRequestsAndFields < ActiveRecord::Migration[8.1]
  def change
    # Link signature requests to envelope and role
    add_reference :signature_requests, :signing_envelope, foreign_key: true, null: true
    add_reference :signature_requests, :signing_role, foreign_key: true, null: true

    # Link fields to their assigned signer role
    add_reference :signature_fields, :signing_role, foreign_key: true, null: true

    # Allow templates to store role labels for multi-signer templates
    add_column :signature_template_fields, :role_label, :string
  end
end
