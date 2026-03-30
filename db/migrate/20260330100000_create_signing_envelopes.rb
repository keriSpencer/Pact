class CreateSigningEnvelopes < ActiveRecord::Migration[8.1]
  def change
    create_table :signing_envelopes do |t|
      t.references :document, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.integer :signing_mode, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :message
      t.datetime :completed_at
      t.datetime :voided_at
      t.references :voided_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :signing_envelopes, :status
  end
end
