module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :ensure_authenticated
    rescue_from UnauthorizedError, with: :handle_unauthorized
  end

  class UnauthorizedError < StandardError; end

  private

  def ensure_authenticated
    return if devise_controller?
    redirect_to new_user_session_path unless user_signed_in?
  end

  def handle_unauthorized
    if request.xhr?
      render json: { error: "You are not authorized to perform this action" }, status: 403
    else
      flash[:alert] = "You are not authorized to perform this action"
      redirect_to root_path
    end
  end

  def require_admin!
    raise UnauthorizedError unless current_user&.can_manage_users?
  end

  def require_contact_access!(contact)
    raise UnauthorizedError unless current_user&.can_manage_contact?(contact)
  end

  def require_user_management!(user)
    raise UnauthorizedError unless current_user&.can_delete_user?(user)
  end

  def require_user_restore!(user)
    raise UnauthorizedError unless current_user&.can_restore_user?(user)
  end

  def require_role_change!(user)
    raise UnauthorizedError unless current_user&.can_change_user_role?(user)
  end
end
