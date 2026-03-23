class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name
      t.string :email, null: false
      t.string :phone
      t.string :company
      t.string :title
      t.string :linkedin_url
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :contacts, [:organization_id, :email], unique: true, where: "deleted_at IS NULL", name: "index_contacts_on_org_and_email_unique"
    add_index :contacts, :deleted_at
    add_index :contacts, :created_at
  end
end
