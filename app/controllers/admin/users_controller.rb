class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_user, only: [:show, :edit, :update, :destroy, :update_role, :restore, :confirm_delete, :process_deletion]

  def index
    @users = organization_users.order(:first_name, :last_name, :email)
    @deleted_users = User.only_deleted.where(organization: current_organization).order(:first_name, :last_name, :email)
  end

  def show
  end

  def edit
    require_role_change!(@user)
  end

  def update
    require_role_change!(@user)

    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    require_user_management!(@user)

    @user.soft_delete!
    redirect_to admin_users_path, notice: "#{@user.full_name} has been deleted."
  end

  def confirm_delete
    require_user_management!(@user)
  end

  def process_deletion
    require_user_management!(@user)

    @user.soft_delete!
    redirect_to admin_users_path, notice: "#{@user.full_name} has been deleted."
  end

  def restore
    require_user_restore!(@user)

    @user.restore!
    redirect_to admin_users_path, notice: "#{@user.full_name} has been restored."
  end

  def update_role
    require_role_change!(@user)

    if @user.update(role: params[:role])
      render json: { success: true, message: "#{@user.full_name}'s role has been updated to #{@user.role.humanize}" }
    else
      render json: { success: false, message: "Failed to update user role: #{@user.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.with_deleted.where(organization: current_organization).find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :role)
  end
end
