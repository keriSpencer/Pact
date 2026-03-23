class CreateSignatureFields < ActiveRecord::Migration[8.0]
  def change
    create_table :signature_fields do |t|
      t.references :signature_request, null: false, foreign_key: true
      t.integer :page_number, null: false, default: 1
      t.decimal :x_percent, precision: 5, scale: 2, null: false
      t.decimal :y_percent, precision: 5, scale: 2, null: false
      t.decimal :width_percent, precision: 5, scale: 2, default: 25.0
      t.decimal :height_percent, precision: 5, scale: 2, default: 8.0
      t.string :field_type, null: false, default: "signature"
      t.string :label
      t.boolean :required, null: false, default: true
      t.integer :position, null: false

      t.timestamps
    end
  end
end
