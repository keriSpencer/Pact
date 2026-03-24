class CreateSignatureTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :signature_templates do |t|
      t.string :name, null: false
      t.text :description
      t.references :document, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.integer :use_count, default: 0, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :signature_templates, [:document_id, :name], unique: true
  end
end
