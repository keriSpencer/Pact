class AddSubscriptionFieldsToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :plan, :string, default: "free", null: false
    add_column :organizations, :stripe_customer_id, :string
    add_column :organizations, :stripe_subscription_id, :string
    add_column :organizations, :subscription_status, :string, default: "active"
    add_column :organizations, :current_period_end, :datetime

    add_index :organizations, :stripe_customer_id, unique: true
    add_index :organizations, :stripe_subscription_id, unique: true
    add_index :organizations, :plan
  end
end
