class Admin::InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def new
    @user = User.new
  end

  def create
    @user = User.invite!(invite_params.merge(organization: current_organization), current_user)

    if @user.errors.empty?
      redirect_to admin_users_path, notice: "Invitation sent to #{@user.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def resend
    @user = current_organization.users.find(params[:id])

    if @user.invitation_pending?
      @user.invite!(nil, current_user)
      redirect_to admin_users_path, notice: "Invitation resent to #{@user.email}."
    else
      redirect_to admin_users_path, alert: "This user has already accepted their invitation."
    end
  end

  private

  def require_admin
    unless current_user.can_invite_users?
      flash[:alert] = "You don't have permission to invite users."
      redirect_to root_path
    end
  end

  def invite_params
    params.require(:user).permit(:email, :first_name, :last_name, :role)
  end
end
