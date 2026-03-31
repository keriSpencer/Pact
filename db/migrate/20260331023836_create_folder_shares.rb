class CreateFolderShares < ActiveRecord::Migration[8.1]
  def change
    create_table :folder_shares do |t|
      t.references :folder, null: false, foreign_key: true
      t.integer :shared_by_id, null: false
      t.string :email, null: false
      t.integer :user_id
      t.string :share_token
      t.integer :permission_level, default: 0, null: false
      t.datetime :expires_at
      t.datetime :accessed_at
      t.datetime :first_access_at
      t.integer :access_count, default: 0, null: false

      t.timestamps
    end
    add_index :folder_shares, :share_token, unique: true
    add_index :folder_shares, [:folder_id, :email], unique: true
    add_index :folder_shares, :user_id
    add_index :folder_shares, :shared_by_id
  end
end
