class SharedDocumentsController < ApplicationController
  skip_before_action :ensure_authenticated
  skip_before_action :set_current_organization

  layout "signing"

  before_action :set_document_share

  def show
    @document_share.record_access!
    @document = @document_share.document
  end

  def download
    @document = @document_share.document
    if @document.file.attached?
      redirect_to rails_blob_path(@document.file, disposition: "attachment"), allow_other_host: true
    else
      flash[:alert] = "File not found."
      redirect_to shared_document_path(@document_share.share_token)
    end
  end

  private

  def set_document_share
    @document_share = DocumentShare.find_by!(share_token: params[:share_token])
    if @document_share.expired?
      render plain: "This shared link has expired.", status: :gone
    end
  end
end
