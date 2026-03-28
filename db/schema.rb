# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_28_200000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "contact_assignments", force: :cascade do |t|
    t.datetime "assigned_at"
    t.integer "contact_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["contact_id", "user_id"], name: "index_contact_assignments_on_contact_id_and_user_id", unique: true
    t.index ["contact_id"], name: "index_contact_assignments_on_contact_id"
    t.index ["user_id"], name: "index_contact_assignments_on_user_id"
  end

  create_table "contact_notes", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.string "contact_type"
    t.datetime "contacted_at"
    t.datetime "created_at", null: false
    t.datetime "follow_up_completed_at"
    t.date "follow_up_date"
    t.text "note", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["contact_id", "contacted_at"], name: "index_contact_notes_on_contact_id_and_contacted_at"
    t.index ["contact_id"], name: "index_contact_notes_on_contact_id"
    t.index ["follow_up_date"], name: "index_contact_notes_on_follow_up_date"
    t.index ["user_id"], name: "index_contact_notes_on_user_id"
  end

  create_table "contact_tags", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.datetime "created_at", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id", "tag_id"], name: "index_contact_tags_on_contact_id_and_tag_id", unique: true
    t.index ["contact_id"], name: "index_contact_tags_on_contact_id"
    t.index ["tag_id"], name: "index_contact_tags_on_tag_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name"
    t.string "linkedin_url"
    t.integer "organization_id", null: false
    t.string "phone"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_contacts_on_created_at"
    t.index ["deleted_at"], name: "index_contacts_on_deleted_at"
    t.index ["organization_id", "email"], name: "index_contacts_on_org_and_email_unique", unique: true, where: "deleted_at IS NULL"
    t.index ["organization_id"], name: "index_contacts_on_organization_id"
  end

  create_table "document_shares", force: :cascade do |t|
    t.integer "access_count", default: 0
    t.datetime "accessed_at"
    t.integer "contact_id"
    t.datetime "created_at", null: false
    t.integer "document_id", null: false
    t.datetime "expires_at"
    t.datetime "first_access_at"
    t.integer "permission_level", null: false
    t.string "share_token"
    t.integer "shared_by_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["contact_id"], name: "index_document_shares_on_contact_id"
    t.index ["document_id"], name: "index_document_shares_on_document_id"
    t.index ["share_token"], name: "index_document_shares_on_share_token", unique: true
    t.index ["shared_by_id"], name: "index_document_shares_on_shared_by_id"
    t.index ["user_id"], name: "index_document_shares_on_user_id"
  end

  create_table "document_versions", force: :cascade do |t|
    t.string "checksum"
    t.datetime "created_at", null: false
    t.integer "document_id", null: false
    t.bigint "file_size"
    t.string "label"
    t.integer "parent_version_id"
    t.integer "signature_request_id"
    t.datetime "updated_at", null: false
    t.string "version_type", default: "original", null: false
    t.index ["document_id", "version_type"], name: "index_document_versions_on_document_id_and_version_type"
    t.index ["document_id"], name: "index_document_versions_on_document_id"
    t.index ["parent_version_id"], name: "index_document_versions_on_parent_version_id"
    t.index ["signature_request_id"], name: "index_document_versions_on_signature_request_id", unique: true, where: "signature_request_id IS NOT NULL"
  end

  create_table "documents", force: :cascade do |t|
    t.integer "contact_id"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "file_hash"
    t.bigint "file_size"
    t.integer "folder_id"
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "version", default: 1, null: false
    t.integer "visibility", default: 0, null: false
    t.index ["contact_id", "created_at"], name: "index_documents_on_contact_id_and_created_at"
    t.index ["contact_id"], name: "index_documents_on_contact_id"
    t.index ["file_hash"], name: "index_documents_on_file_hash"
    t.index ["folder_id"], name: "index_documents_on_folder_id"
    t.index ["organization_id"], name: "index_documents_on_organization_id"
    t.index ["status", "visibility"], name: "index_documents_on_status_and_visibility"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.integer "parent_id"
    t.string "path", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["deleted_at"], name: "index_folders_on_deleted_at"
    t.index ["organization_id", "path"], name: "index_folders_on_organization_id_and_path", unique: true
    t.index ["organization_id"], name: "index_folders_on_organization_id"
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.text "description"
    t.string "name", null: false
    t.string "plan", default: "free", null: false
    t.string "schema_name"
    t.string "slug", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status", default: "active"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_organizations_on_active"
    t.index ["name"], name: "index_organizations_on_name"
    t.index ["plan"], name: "index_organizations_on_plan"
    t.index ["schema_name"], name: "index_organizations_on_schema_name", unique: true
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.index ["stripe_customer_id"], name: "index_organizations_on_stripe_customer_id", unique: true
    t.index ["stripe_subscription_id"], name: "index_organizations_on_stripe_subscription_id", unique: true
  end

  create_table "signature_artifacts", force: :cascade do |t|
    t.text "artifact_data", null: false
    t.string "artifact_type", default: "signature", null: false
    t.string "capture_method", default: "typed", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.integer "signature_request_id", null: false
    t.string "signer_email", null: false
    t.string "typed_text"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.index ["signature_request_id"], name: "index_signature_artifacts_on_signature_request_id"
  end

  create_table "signature_field_completions", force: :cascade do |t|
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.integer "signature_artifact_id", null: false
    t.integer "signature_field_id", null: false
    t.string "signer_email", null: false
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.index ["signature_artifact_id"], name: "index_signature_field_completions_on_signature_artifact_id"
    t.index ["signature_field_id"], name: "index_signature_field_completions_on_signature_field_id", unique: true
  end

  create_table "signature_fields", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "field_type", default: "signature", null: false
    t.decimal "height_percent", precision: 5, scale: 2, default: "8.0"
    t.string "label"
    t.integer "page_number", default: 1, null: false
    t.integer "position", null: false
    t.boolean "required", default: true, null: false
    t.integer "signature_request_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "width_percent", precision: 5, scale: 2, default: "25.0"
    t.decimal "x_percent", precision: 5, scale: 2, null: false
    t.decimal "y_percent", precision: 5, scale: 2, null: false
    t.index ["signature_request_id"], name: "index_signature_fields_on_signature_request_id"
  end

  create_table "signature_requests", force: :cascade do |t|
    t.boolean "auto_matched", default: false
    t.integer "contact_id"
    t.datetime "created_at", null: false
    t.text "decline_reason"
    t.integer "document_id", null: false
    t.datetime "expires_at"
    t.integer "fields_completed_count", default: 0
    t.integer "fields_required_count", default: 0
    t.string "ip_address"
    t.datetime "last_edited_at"
    t.text "message"
    t.integer "requester_id", null: false
    t.datetime "sent_at"
    t.text "signature_data"
    t.decimal "signature_height", precision: 5, scale: 2, default: "8.0"
    t.integer "signature_page", default: 1
    t.string "signature_token", null: false
    t.decimal "signature_width", precision: 5, scale: 2, default: "25.0"
    t.decimal "signature_x", precision: 5, scale: 2
    t.decimal "signature_y", precision: 5, scale: 2
    t.datetime "signed_at"
    t.string "signer_email"
    t.integer "signer_id"
    t.string "signer_name"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.datetime "viewed_at"
    t.datetime "voided_at"
    t.integer "voided_by_id"
    t.index ["contact_id"], name: "index_signature_requests_on_contact_id"
    t.index ["document_id"], name: "index_signature_requests_on_document_id"
    t.index ["requester_id"], name: "index_signature_requests_on_requester_id"
    t.index ["signature_token"], name: "index_signature_requests_on_signature_token", unique: true
    t.index ["signer_email"], name: "index_signature_requests_on_signer_email"
    t.index ["signer_id"], name: "index_signature_requests_on_signer_id"
    t.index ["status"], name: "index_signature_requests_on_status"
    t.index ["voided_by_id"], name: "index_signature_requests_on_voided_by_id"
  end

  create_table "signature_template_fields", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "field_type", default: "signature", null: false
    t.decimal "height_percent", precision: 5, scale: 2, default: "8.0"
    t.string "label"
    t.integer "page_number", default: 1, null: false
    t.integer "position", null: false
    t.boolean "required", default: true, null: false
    t.integer "signature_template_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "width_percent", precision: 5, scale: 2, default: "25.0"
    t.decimal "x_percent", precision: 5, scale: 2, null: false
    t.decimal "y_percent", precision: 5, scale: 2, null: false
    t.index ["signature_template_id"], name: "index_signature_template_fields_on_signature_template_id"
  end

  create_table "signature_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "document_id", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.datetime "updated_at", null: false
    t.integer "use_count", default: 0, null: false
    t.integer "user_id", null: false
    t.index ["document_id", "name"], name: "index_signature_templates_on_document_id_and_name", unique: true
    t.index ["document_id"], name: "index_signature_templates_on_document_id"
    t.index ["organization_id"], name: "index_signature_templates_on_organization_id"
    t.index ["user_id"], name: "index_signature_templates_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_tags_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_tags_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", default: "", null: false
    t.boolean "email_notifications", default: true, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.string "last_name"
    t.integer "organization_id"
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.string "timezone", default: "UTC"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contact_assignments", "contacts"
  add_foreign_key "contact_assignments", "users"
  add_foreign_key "contact_notes", "contacts"
  add_foreign_key "contact_notes", "users"
  add_foreign_key "contact_tags", "contacts"
  add_foreign_key "contact_tags", "tags"
  add_foreign_key "contacts", "organizations"
  add_foreign_key "document_shares", "contacts"
  add_foreign_key "document_shares", "documents"
  add_foreign_key "document_shares", "users"
  add_foreign_key "document_shares", "users", column: "shared_by_id"
  add_foreign_key "document_versions", "document_versions", column: "parent_version_id"
  add_foreign_key "document_versions", "documents"
  add_foreign_key "document_versions", "signature_requests"
  add_foreign_key "documents", "contacts"
  add_foreign_key "documents", "folders"
  add_foreign_key "documents", "organizations"
  add_foreign_key "documents", "users"
  add_foreign_key "folders", "folders", column: "parent_id"
  add_foreign_key "folders", "organizations"
  add_foreign_key "folders", "users"
  add_foreign_key "signature_artifacts", "signature_requests"
  add_foreign_key "signature_field_completions", "signature_artifacts"
  add_foreign_key "signature_field_completions", "signature_fields"
  add_foreign_key "signature_fields", "signature_requests"
  add_foreign_key "signature_requests", "contacts"
  add_foreign_key "signature_requests", "documents"
  add_foreign_key "signature_requests", "users", column: "requester_id"
  add_foreign_key "signature_requests", "users", column: "signer_id"
  add_foreign_key "signature_requests", "users", column: "voided_by_id"
  add_foreign_key "signature_template_fields", "signature_templates"
  add_foreign_key "signature_templates", "documents"
  add_foreign_key "signature_templates", "organizations"
  add_foreign_key "signature_templates", "users"
  add_foreign_key "tags", "organizations"
  add_foreign_key "users", "organizations"
end
