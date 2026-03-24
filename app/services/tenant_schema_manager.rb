class TenantSchemaManager
  # Tables that exist per-tenant (in their own schema) when using PostgreSQL
  TENANT_TABLES = %w[
    contacts contact_assignments contact_notes contact_tags tags
    documents document_versions document_shares folders
    signature_requests signature_fields signature_artifacts
    signature_field_completions signature_templates signature_template_fields
  ].freeze

  # Tables that remain in the public schema
  PUBLIC_TABLES = %w[
    organizations users
    active_storage_blobs active_storage_attachments active_storage_variant_records
  ].freeze

  def self.create_schema_for(organization)
    return unless postgresql?
    return unless organization.schema_name.present?

    conn = ActiveRecord::Base.connection
    conn.execute("CREATE SCHEMA IF NOT EXISTS #{conn.quote_column_name(organization.schema_name)}")
    create_tables_for(organization.schema_name)
  end

  def self.drop_schema(schema_name)
    return unless postgresql?

    conn = ActiveRecord::Base.connection
    conn.execute("DROP SCHEMA IF EXISTS #{conn.quote_column_name(schema_name)} CASCADE")
  end

  def self.create_tables_for(schema_name)
    return unless postgresql?

    conn = ActiveRecord::Base.connection

    # Set search path to the tenant schema
    conn.execute("SET search_path TO #{conn.quote_column_name(schema_name)}")

    create_contacts_table(conn)
    create_contact_assignments_table(conn)
    create_contact_notes_table(conn)
    create_tags_table(conn)
    create_contact_tags_table(conn)
    create_folders_table(conn)
    create_documents_table(conn)
    create_document_versions_table(conn)
    create_document_shares_table(conn)
    create_signature_requests_table(conn)
    create_signature_fields_table(conn)
    create_signature_artifacts_table(conn)
    create_signature_field_completions_table(conn)
    create_signature_templates_table(conn)
    create_signature_template_fields_table(conn)

    # Reset search path
    conn.execute("SET search_path TO public")
  end

  def self.postgresql?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
  end

  class << self
    private

    def create_contacts_table(conn)
      return if conn.table_exists?(:contacts)
      conn.create_table :contacts do |t|
        t.bigint :organization_id, null: false
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
      conn.add_index :contacts, [:organization_id, :email], unique: true, where: "deleted_at IS NULL", name: "idx_contacts_org_email"
    end

    def create_contact_assignments_table(conn)
      return if conn.table_exists?(:contact_assignments)
      conn.create_table :contact_assignments do |t|
        t.bigint :contact_id, null: false
        t.bigint :user_id
        t.datetime :assigned_at
        t.timestamps
      end
      conn.add_index :contact_assignments, [:contact_id, :user_id], unique: true
    end

    def create_contact_notes_table(conn)
      return if conn.table_exists?(:contact_notes)
      conn.create_table :contact_notes do |t|
        t.bigint :contact_id, null: false
        t.bigint :user_id
        t.text :note, null: false
        t.string :contact_type
        t.datetime :contacted_at
        t.date :follow_up_date
        t.datetime :follow_up_completed_at
        t.timestamps
      end
    end

    def create_tags_table(conn)
      return if conn.table_exists?(:tags)
      conn.create_table :tags do |t|
        t.bigint :organization_id, null: false
        t.string :name, null: false
        t.string :color, null: false
        t.text :description
        t.timestamps
      end
      conn.add_index :tags, [:organization_id, :name], unique: true
    end

    def create_contact_tags_table(conn)
      return if conn.table_exists?(:contact_tags)
      conn.create_table :contact_tags do |t|
        t.bigint :contact_id, null: false
        t.bigint :tag_id, null: false
        t.timestamps
      end
      conn.add_index :contact_tags, [:contact_id, :tag_id], unique: true
    end

    def create_folders_table(conn)
      return if conn.table_exists?(:folders)
      conn.create_table :folders do |t|
        t.bigint :organization_id, null: false
        t.bigint :user_id, null: false
        t.bigint :parent_id
        t.string :name, null: false
        t.text :description
        t.string :path, null: false
        t.integer :visibility, null: false, default: 0
        t.datetime :deleted_at
        t.timestamps
      end
      conn.add_index :folders, [:organization_id, :path], unique: true
    end

    def create_documents_table(conn)
      return if conn.table_exists?(:documents)
      conn.create_table :documents do |t|
        t.bigint :organization_id, null: false
        t.bigint :user_id, null: false
        t.bigint :folder_id
        t.bigint :contact_id
        t.string :name, null: false
        t.text :description
        t.bigint :file_size
        t.string :content_type
        t.integer :visibility, null: false, default: 0
        t.integer :status, null: false, default: 0
        t.string :file_hash
        t.integer :version, null: false, default: 1
        t.timestamps
      end
    end

    def create_document_versions_table(conn)
      return if conn.table_exists?(:document_versions)
      conn.create_table :document_versions do |t|
        t.bigint :document_id, null: false
        t.bigint :signature_request_id
        t.bigint :parent_version_id
        t.string :version_type, null: false, default: "original"
        t.string :label
        t.bigint :file_size
        t.string :checksum
        t.timestamps
      end
    end

    def create_document_shares_table(conn)
      return if conn.table_exists?(:document_shares)
      conn.create_table :document_shares do |t|
        t.bigint :document_id, null: false
        t.bigint :user_id
        t.bigint :contact_id
        t.bigint :shared_by_id, null: false
        t.integer :permission_level, null: false
        t.string :share_token
        t.datetime :expires_at
        t.datetime :accessed_at
        t.datetime :first_access_at
        t.integer :access_count, default: 0
        t.timestamps
      end
      conn.add_index :document_shares, :share_token, unique: true
    end

    def create_signature_requests_table(conn)
      return if conn.table_exists?(:signature_requests)
      conn.create_table :signature_requests do |t|
        t.bigint :document_id, null: false
        t.bigint :requester_id, null: false
        t.bigint :signer_id
        t.bigint :contact_id
        t.string :signer_email
        t.string :signer_name
        t.integer :status, default: 0
        t.text :message
        t.datetime :signed_at
        t.datetime :sent_at
        t.datetime :viewed_at
        t.text :signature_data
        t.datetime :expires_at
        t.string :signature_token, null: false
        t.decimal :signature_x, precision: 5, scale: 2
        t.decimal :signature_y, precision: 5, scale: 2
        t.integer :signature_page, default: 1
        t.decimal :signature_width, precision: 5, scale: 2, default: 25.0
        t.decimal :signature_height, precision: 5, scale: 2, default: 8.0
        t.integer :fields_completed_count, default: 0
        t.integer :fields_required_count, default: 0
        t.datetime :voided_at
        t.bigint :voided_by_id
        t.text :decline_reason
        t.string :ip_address
        t.text :user_agent
        t.datetime :last_edited_at
        t.boolean :auto_matched, default: false
        t.timestamps
      end
      conn.add_index :signature_requests, :signature_token, unique: true
    end

    def create_signature_fields_table(conn)
      return if conn.table_exists?(:signature_fields)
      conn.create_table :signature_fields do |t|
        t.bigint :signature_request_id, null: false
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

    def create_signature_artifacts_table(conn)
      return if conn.table_exists?(:signature_artifacts)
      conn.create_table :signature_artifacts do |t|
        t.bigint :signature_request_id, null: false
        t.string :signer_email, null: false
        t.string :artifact_type, null: false, default: "signature"
        t.text :artifact_data, null: false
        t.string :typed_text
        t.string :capture_method, null: false, default: "typed"
        t.string :ip_address
        t.text :user_agent
        t.timestamps
      end
    end

    def create_signature_field_completions_table(conn)
      return if conn.table_exists?(:signature_field_completions)
      conn.create_table :signature_field_completions do |t|
        t.bigint :signature_field_id, null: false
        t.bigint :signature_artifact_id, null: false
        t.string :signer_email, null: false
        t.string :ip_address
        t.text :user_agent
        t.datetime :completed_at, null: false
        t.timestamps
      end
      conn.add_index :signature_field_completions, :signature_field_id, unique: true
    end

    def create_signature_templates_table(conn)
      return if conn.table_exists?(:signature_templates)
      conn.create_table :signature_templates do |t|
        t.string :name, null: false
        t.text :description
        t.bigint :document_id, null: false
        t.bigint :user_id, null: false
        t.bigint :organization_id, null: false
        t.integer :use_count, default: 0
        t.datetime :last_used_at
        t.timestamps
      end
    end

    def create_signature_template_fields_table(conn)
      return if conn.table_exists?(:signature_template_fields)
      conn.create_table :signature_template_fields do |t|
        t.bigint :signature_template_id, null: false
        t.integer :page_number, null: false, default: 1
        t.decimal :x_percent, precision: 5, scale: 2, null: false
        t.decimal :y_percent, precision: 5, scale: 2, null: false
        t.decimal :width_percent, precision: 5, scale: 2, default: 25.0
        t.decimal :height_percent, precision: 5, scale: 2, default: 8.0
        t.string :field_type, null: false, default: "signature"
        t.string :label
        t.boolean :required, null: false, default: true
        t.integer :position, null: false, default: 1
        t.timestamps
      end
    end
  end
end
