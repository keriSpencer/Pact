class AddSchemaNameToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :schema_name, :string
    add_index :organizations, :schema_name, unique: true
  end
end
