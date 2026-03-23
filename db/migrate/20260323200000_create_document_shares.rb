class CreateDocumentShares < ActiveRecord::Migration[8.0]
  def change
    create_table :document_shares do |t|
      t.references :document, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :contact, foreign_key: true
      t.references :shared_by, null: false, foreign_key: { to_table: :users }
      t.integer :permission_level, null: false
      t.string :share_token
      t.datetime :expires_at
      t.datetime :accessed_at
      t.datetime :first_access_at
      t.integer :access_count, default: 0

      t.timestamps
    end

    add_index :document_shares, :share_token, unique: true
  end
end
