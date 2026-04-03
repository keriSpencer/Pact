class AddSavedSignatureToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :saved_signature, :text
    add_column :users, :saved_initials, :text
  end
end
