class CreateContactAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_assignments do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.datetime :assigned_at

      t.timestamps
    end

    add_index :contact_assignments, [:contact_id, :user_id], unique: true
  end
end
