class CreateSignatureArtifacts < ActiveRecord::Migration[8.0]
  def change
    create_table :signature_artifacts do |t|
      t.references :signature_request, null: false, foreign_key: true
      t.string :signer_email, null: false
      t.string :artifact_type, null: false, default: "signature"
      t.text :artifact_data, null: false
      t.string :typed_text
      t.string :capture_method, null: false, default: "typed"
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end
  end
end
