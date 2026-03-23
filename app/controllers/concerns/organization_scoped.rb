module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_current_organization
    helper_method :current_organization
  end

  private

  def current_organization
    @current_organization ||= current_user&.organization
  end

  def set_current_organization
    Current.organization = current_organization if user_signed_in?
  end

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
