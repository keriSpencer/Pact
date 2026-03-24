class DocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document, only: [:show, :edit, :update, :destroy, :download, :preview, :versions]
  before_action :check_document_access, only: [:show, :edit, :update, :destroy, :download, :preview, :versions]

  def index
    @documents = current_user.documents.active
                             .includes(:user, :folder, :contact)
                             .order(created_at: :desc)

    if params[:folder_id].present?
      @folder = Folder.find(params[:folder_id])
      @documents = @folder.documents.active.visible_to(current_user).includes(:user).order(:name)
      @breadcrumbs = @folder.breadcrumbs
    else
      @documents = @documents.where(folder_id: nil)
      @page_title = "Unfiled"
    end

    if params[:contact_id].present?
      @contact = organization_contacts.find(params[:contact_id])
      @documents = organization_documents.active.where(contact: @contact).includes(:user).order(created_at: :desc)
      @page_title = "Documents for #{@contact.full_name}"
    end

    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @documents = @documents.where("LOWER(name) LIKE ? OR LOWER(description) LIKE ?", search_term, search_term)
    end
  end

  def show
  end

  def new
    @document = Document.new
    @document.folder_id = params[:folder_id] if params[:folder_id].present?
    @folders = Folder.visible_to(current_user).order(:path)
  end

  def create
    @document = Document.new(document_params)
    @document.user = current_user
    @document.organization = current_organization

    if @document.save
      redirect_to @document, notice: "Document uploaded."
    else
      @folders = Folder.visible_to(current_user).order(:path)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @folders = Folder.visible_to(current_user).order(:path)
  end

  def update
    if @document.update(document_params)
      redirect_to @document, notice: "Document updated."
    else
      @folders = Folder.visible_to(current_user).order(:path)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @document.user == current_user || current_user.can_manage_users?
      flash[:alert] = "You don't have permission to delete this document."
      redirect_to @document
      return
    end

    was_deleted = @document.safe_destroy!

    if was_deleted
      redirect_to documents_path, notice: "Document deleted."
    else
      redirect_to documents_path, notice: "Document archived. Signed versions are preserved in the Signed Archive for legal compliance."
    end
  end

  def archive
    @documents = organization_documents.where(status: :archived)
                                       .includes(:user, :signature_requests)
                                       .order(updated_at: :desc)
  end

  def download
    if @document.file.attached?
      unless @document.verify_integrity!
        Rails.logger.error "Document integrity check failed for document #{@document.id}"
        flash[:alert] = "Document integrity could not be verified. Please contact support."
        redirect_to @document
        return
      end
      redirect_to rails_blob_path(@document.file, disposition: "attachment"), allow_other_host: true
    else
      flash[:alert] = "File not found."
      redirect_to @document
    end
  end

  def preview
    if @document.file.attached?
      redirect_to rails_blob_path(@document.file, disposition: "inline")
    else
      head :not_found
    end
  end

  def versions
    @versions = @document.versions.in_order.includes(:signature_request)
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def check_document_access
    unless @document.can_access?(current_user)
      flash[:alert] = "You don't have permission to access this document."
      redirect_to documents_path
    end
  end

  def document_params
    params.require(:document).permit(:name, :description, :file, :folder_id, :contact_id, :visibility)
  end
end
