class DocumentSharesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document

  def create
    existing = @document.document_shares.where(user_id: nil, contact_id: nil).active.first
    if existing
      @share = existing
    else
      @share = @document.document_shares.build(
        shared_by: current_user,
        permission_level: :view,
        expires_at: 30.days.from_now
      )
      @share.save!
    end

    respond_to do |format|
      format.html { redirect_to @document, notice: "Share link created." }
      format.turbo_stream
    end
  end

  def destroy
    @share = @document.document_shares.find(params[:id])
    @share.destroy!

    respond_to do |format|
      format.html { redirect_to @document, notice: "Share link removed." }
      format.turbo_stream
    end
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
    unless @document.can_access?(current_user)
      flash[:alert] = "You don't have permission to access this document."
      redirect_to documents_path
    end
  end
end
