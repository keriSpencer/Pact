class FoldersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_folder, only: [:show, :edit, :update, :destroy, :confirm_delete, :restore]
  before_action :check_folder_access, only: [:show, :edit, :update, :destroy, :confirm_delete]

  def index
    @folders = Folder.visible_to(current_user)
                     .root_folders
                     .includes(:user, :subfolders, :documents)
                     .order(:name)

    @unfiled_count = current_user.documents.active.where(folder_id: nil).count
  end

  def show
    @subfolders = @folder.subfolders.visible_to(current_user).order(:name)
    @documents = @folder.documents.active
                        .visible_to(current_user)
                        .includes(:user)
                        .order(:name)
    @breadcrumbs = @folder.breadcrumbs
  end

  def new
    @folder = Folder.new
    @folder.parent = Folder.find(params[:parent_id]) if params[:parent_id].present?
  end

  def create
    @folder = Folder.new(folder_params)
    @folder.user = current_user
    @folder.organization = current_organization

    if @folder.save
      redirect_to @folder, notice: "Folder created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @folder.update(folder_params)
      redirect_to @folder, notice: "Folder updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm_delete
    # Show confirmation page with contents summary
  end

  def destroy
    parent = @folder.parent
    @folder.destroy
    notice = "Folder '#{@folder.name}' deleted. Documents have been moved to Unfiled."
    redirect_to(parent || folders_path, notice: notice)
  end

  def restore
    @folder = Folder.with_deleted.find(params[:id])
    @folder.restore!
    redirect_to @folder, notice: "Folder '#{@folder.name}' restored."
  end

  private

  def set_folder
    @folder = Folder.find(params[:id])
  end

  def check_folder_access
    unless @folder.can_access?(current_user)
      flash[:alert] = "You don't have permission to access this folder."
      redirect_to folders_path
    end
  end

  def folder_params
    params.require(:folder).permit(:name, :description, :visibility, :parent_id)
  end
end
