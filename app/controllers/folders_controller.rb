class FoldersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_folder, only: [:show, :edit, :update, :destroy, :confirm_delete, :restore]
  before_action :check_folder_access, only: [:show, :edit, :update, :destroy, :confirm_delete]

  def index
    all_folders = Folder.visible_to_with_shared(current_user)
    @folders = all_folders.select { |f| f.parent_id.nil? }.sort_by(&:name)

    @unfiled_count = current_user.documents.active.where(folder_id: nil).count
  end

  def show
    cross_org = @folder.organization_id != current_user.organization_id
    if cross_org
      Folder.with_public_search_path do
        @subfolders = Folder.unscoped.where(deleted_at: nil, parent_id: @folder.id).order(:name).to_a
        @documents = Document.unscoped.where(folder_id: @folder.id, status: :active).includes(:user).order(:name).to_a
        @breadcrumbs = build_cross_org_breadcrumbs(@folder)
      end
    else
      @subfolders = @folder.subfolders.visible_to(current_user).order(:name)
      @documents = @folder.documents.active
                          .visible_to(current_user)
                          .includes(:user)
                          .order(:name)
      @breadcrumbs = @folder.breadcrumbs
    end
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
    @folder = Folder.find_shared(params[:id], current_user)
    unless @folder
      flash[:alert] = "Folder not found."
      redirect_to folders_path
    end
  end

  def check_folder_access
    has_access = if @folder.organization_id == current_user.organization_id
                   @folder.can_access?(current_user)
                 else
                   # Cross-org: already verified by find_shared
                   true
                 end
    unless has_access
      flash[:alert] = "You don't have permission to access this folder."
      redirect_to folders_path
    end
  end

  def folder_params
    params.require(:folder).permit(:name, :description, :visibility, :parent_id)
  end

  def build_cross_org_breadcrumbs(folder)
    crumbs = [folder]
    current = folder
    while current.parent_id
      parent = Folder.unscoped.where(deleted_at: nil).find_by(id: current.parent_id)
      break unless parent
      crumbs.unshift(parent)
      current = parent
    end
    crumbs
  end
end
