class CreateFolders < ActiveRecord::Migration[8.0]
  def change
    create_table :folders do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :folders }
      t.string :name, null: false
      t.text :description
      t.string :path, null: false
      t.integer :visibility, null: false, default: 0

      t.timestamps
    end

    add_index :folders, [:organization_id, :path], unique: true
  end
end
