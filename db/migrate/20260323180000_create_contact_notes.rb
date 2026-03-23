class CreateContactNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_notes do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.text :note, null: false
      t.string :contact_type
      t.datetime :contacted_at
      t.date :follow_up_date
      t.datetime :follow_up_completed_at

      t.timestamps
    end

    add_index :contact_notes, [:contact_id, :contacted_at]
    add_index :contact_notes, :follow_up_date
  end
end
