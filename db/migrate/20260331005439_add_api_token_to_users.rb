class AddApiTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :api_token, :string
    add_column :users, :api_token_created_at, :datetime
    add_index :users, :api_token, unique: true
  end
end
