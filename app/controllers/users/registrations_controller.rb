class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def build_resource(hash = {})
    super

    if resource.organization.blank?
      org_name = [resource.first_name, resource.last_name].compact_blank.join(" ").presence || "My Organization"
      resource.organization = Organization.new(name: org_name, active: true)
      resource.role = :admin
    end
  end

  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password)
  end

  def after_sign_up_path_for(resource)
    billing_path
  end
end
