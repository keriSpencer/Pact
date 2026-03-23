class Users::InvitationsController < Devise::InvitationsController
  protected

  def after_accept_path_for(_resource)
    root_path
  end
end
