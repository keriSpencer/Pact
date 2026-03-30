class CreateSigningRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :signing_roles do |t|
      t.references :signing_envelope, null: false, foreign_key: true
      t.string :label, null: false
      t.string :color, null: false, default: "#3B82F6"
      t.string :signer_email
      t.string :signer_name
      t.integer :signing_order, null: false, default: 0
      t.boolean :is_self_signer, null: false, default: false
      t.references :contact, foreign_key: true

      t.timestamps
    end

    add_index :signing_roles, [:signing_envelope_id, :label], unique: true
    add_index :signing_roles, [:signing_envelope_id, :signing_order]
  end
end
