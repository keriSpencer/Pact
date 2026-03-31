class SharedFoldersController < ApplicationController
  skip_before_action :ensure_authenticated
  skip_before_action :set_current_organization

  rate_limit to: 10, within: 1.minute, by: -> { request.remote_ip }, with: -> { head :too_many_requests }

  layout "signing"

  before_action :set_folder_share

  def show
    @folder_share.record_access!
    @folder = @folder_share.folder
    @subfolders = @folder.subfolders.order(:name)
    @documents = @folder.documents.where(status: :active).order(:name)
  end

  def subfolder
    @folder_share.record_access!
    @root_folder = @folder_share.folder
    @folder = find_subfolder(params[:subfolder_id])

    if @folder.nil?
      render plain: "Folder not found.", status: :not_found
      return
    end

    @subfolders = @folder.subfolders.order(:name)
    @documents = @folder.documents.where(status: :active).order(:name)
    render :show
  end

  def download
    @folder_share.record_access!
    document = find_accessible_document(params[:document_id])

    if document&.file&.attached?
      redirect_to rails_blob_path(document.file, disposition: "attachment"), allow_other_host: true
    else
      flash[:alert] = "File not found."
      redirect_to shared_folder_path(@folder_share.share_token)
    end
  end

  private

  def set_folder_share
    @folder_share = FolderShare.find_by!(share_token: params[:share_token])
    if @folder_share.expired?
      render plain: "This shared link has expired.", status: :gone
    end
  end

  def find_subfolder(id)
    # Only allow access to subfolders within the shared folder tree
    subfolder = Folder.find_by(id: id)
    return nil unless subfolder
    return nil unless descendant_of?(@folder_share.folder, subfolder)
    subfolder
  end

  def find_accessible_document(id)
    document = Document.find_by(id: id)
    return nil unless document
    folder = document.folder
    return nil unless folder
    return nil unless folder == @folder_share.folder || descendant_of?(@folder_share.folder, folder)
    document
  end

  def descendant_of?(ancestor, folder)
    current = folder
    while current
      return true if current.id == ancestor.id
      current = current.parent
    end
    false
  end
end
