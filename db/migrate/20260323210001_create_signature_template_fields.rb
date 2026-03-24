class CreateSignatureTemplateFields < ActiveRecord::Migration[8.0]
  def change
    create_table :signature_template_fields do |t|
      t.references :signature_template, null: false, foreign_key: true
      t.integer :page_number, default: 1, null: false
      t.decimal :x_percent, precision: 5, scale: 2, null: false
      t.decimal :y_percent, precision: 5, scale: 2, null: false
      t.decimal :width_percent, precision: 5, scale: 2, default: 25.0
      t.decimal :height_percent, precision: 5, scale: 2, default: 8.0
      t.string :field_type, default: "signature", null: false
      t.string :label
      t.boolean :required, default: true, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end
