module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_current_organization
    after_action :reset_tenant_schema
    helper_method :current_organization
  end

  private

  def current_organization
    @current_organization ||= current_user&.organization
  end

  def set_current_organization
    if user_signed_in? && current_organization
      Current.organization = current_organization
      switch_to_tenant_schema
    end
  end

  def switch_to_tenant_schema
    return unless current_organization&.schema_name.present?
    return unless ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")

    ActiveRecord::Base.connection.execute(
      "SET search_path TO #{ActiveRecord::Base.connection.quote_column_name(current_organization.schema_name)}, public"
    )
  end

  def reset_tenant_schema
    return unless user_signed_in?
    return unless ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")

    ActiveRecord::Base.connection.execute("SET search_path TO public")
  end

  # Scope helpers remain for backward compatibility during migration
  def organization_users
    current_organization.users
  end

  def organization_contacts
    current_organization.contacts
  end

  def organization_documents
    current_organization.documents
  end

  def organization_folders
    current_organization.folders
  end

  def organization_activities
    current_organization.activities
  end
end
