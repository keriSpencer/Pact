class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :folder, foreign_key: true
      t.references :contact, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.bigint :file_size
      t.string :content_type
      t.integer :visibility, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :file_hash
      t.integer :version, null: false, default: 1

      t.timestamps
    end

    add_index :documents, :file_hash
    add_index :documents, [:status, :visibility]
    add_index :documents, [:contact_id, :created_at]
  end
end
