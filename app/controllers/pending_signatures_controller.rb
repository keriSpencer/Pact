class PendingSignaturesController < ApplicationController
  before_action :authenticate_user!

  def index
    @signed_filter = params[:filter] == "signed"

    base_scope = SignatureRequest.joins(:document)
      .where(documents: { organization_id: current_organization.id })

    if @signed_filter
      @requests = base_scope
        .where(status: :signed)
        .includes(:document, :signing_role, :signing_envelope)
        .order(signed_at: :desc)
      @page_title = "Signed"
    else
      @requests = base_scope
        .where(status: [:pending, :sent, :viewed])
        .includes(:document, :signing_role, :signing_envelope)
        .order(created_at: :desc)
      @page_title = "Pending Signatures"
    end

    @pending_count = base_scope.where(status: [:pending, :sent, :viewed]).count
    @signed_count = base_scope.where(status: :signed).count
  end
end
