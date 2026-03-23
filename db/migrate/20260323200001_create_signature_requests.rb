class CreateSignatureRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :signature_requests do |t|
      t.references :document, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :signer, foreign_key: { to_table: :users }
      t.references :contact, foreign_key: true
      t.string :signer_email
      t.string :signer_name
      t.integer :status, default: 0
      t.text :message
      t.datetime :signed_at
      t.datetime :sent_at
      t.datetime :viewed_at
      t.text :signature_data
      t.datetime :expires_at
      t.string :signature_token, null: false
      t.decimal :signature_x, precision: 5, scale: 2
      t.decimal :signature_y, precision: 5, scale: 2
      t.integer :signature_page, default: 1
      t.decimal :signature_width, precision: 5, scale: 2, default: 25.0
      t.decimal :signature_height, precision: 5, scale: 2, default: 8.0
      t.integer :fields_completed_count, default: 0
      t.integer :fields_required_count, default: 0
      t.datetime :voided_at
      t.references :voided_by, foreign_key: { to_table: :users }
      t.text :decline_reason
      t.string :ip_address
      t.text :user_agent
      t.datetime :last_edited_at
      t.boolean :auto_matched, default: false

      t.timestamps
    end

    add_index :signature_requests, :signer_email
    add_index :signature_requests, :signature_token, unique: true
    add_index :signature_requests, :status
  end
end
