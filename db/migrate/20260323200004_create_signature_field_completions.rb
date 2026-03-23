class CreateSignatureFieldCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :signature_field_completions do |t|
      t.references :signature_field, null: false, foreign_key: true, index: { unique: true }
      t.references :signature_artifact, null: false, foreign_key: true
      t.string :signer_email, null: false
      t.string :ip_address
      t.text :user_agent
      t.datetime :completed_at, null: false

      t.timestamps
    end
  end
end
