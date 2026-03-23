class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update]
  before_action :ensure_current_user, only: [:edit, :update]

  def index
    @users = organization_users.where.not(id: current_user.id).order(:first_name, :last_name)

    respond_to do |format|
      format.html
      format.json {
        render json: @users.select(:id, :first_name, :last_name, :email).map do |user|
          {
            id: user.id,
            display_name: "#{user.first_name} #{user.last_name}".strip,
            email: user.email
          }
        end
      }
    end
  end

  def show
  end

  def profile
    @user = current_user
    redirect_to user_path(current_user)
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "Profile was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = organization_users.find(params[:id])
  end

  def ensure_current_user
    redirect_to root_path, alert: "Access denied." unless @user == current_user
  end

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :title, :phone)
  end
end
