class CreateDocumentVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :document_versions do |t|
      t.references :document, null: false, foreign_key: true
      t.references :signature_request, foreign_key: true, index: false
      t.references :parent_version, foreign_key: { to_table: :document_versions }
      t.string :version_type, null: false, default: "original"
      t.string :label
      t.bigint :file_size
      t.string :checksum

      t.timestamps
    end

    add_index :document_versions, [:document_id, :version_type]
    add_index :document_versions, :signature_request_id, unique: true, where: "signature_request_id IS NOT NULL"
  end
end
