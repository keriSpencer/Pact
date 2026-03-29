class SignatureRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document
  before_action :set_signature_request, only: [:edit, :update, :autosave, :discard_draft, :cancel, :resend, :void]
  before_action :check_document_access

  def new
    @signature_request = @document.signature_requests.create!(
      requester: current_user,
      status: :draft,
      signer_email: params[:signer_email] || "",
      signer_name: params[:signer_name] || ""
    )
    @signature_fields = @signature_request.signature_fields.order(:position)
    render :edit
  end

  def edit
    @signature_fields = @signature_request.signature_fields.order(:position)
  end

  def update
    @signature_request.assign_attributes(signature_request_params)
    sync_fields_from_json

    if params[:send_request].present?
      if @signature_request.signer_email.blank?
        flash.now[:alert] = "Signer email is required before sending."
        @signature_fields = @signature_request.signature_fields.reload.order(:position)
        render :edit, status: :unprocessable_entity
        return
      end

      if @signature_request.save
        @signature_request.send_signature_request!
        redirect_to document_path(@document), notice: "Signature request sent to #{@signature_request.signer_display_name}."
      else
        flash.now[:alert] = @signature_request.errors.full_messages.join(", ")
        @signature_fields = @signature_request.signature_fields.reload.order(:position)
        render :edit, status: :unprocessable_entity
      end
    else
      if @signature_request.save
        redirect_to edit_document_signature_request_path(@document, @signature_request), notice: "Draft saved."
      else
        @signature_fields = @signature_request.signature_fields.order(:position)
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def autosave
    sync_fields_from_json
    @signature_request.assign_attributes(signature_request_params.merge(last_edited_at: Time.current))
    if @signature_request.save
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def discard_draft
    if @signature_request.draft?
      @signature_request.destroy
      redirect_to document_path(@document), notice: "Draft discarded."
    else
      redirect_to document_path(@document), alert: "Only drafts can be discarded."
    end
  end

  def cancel
    if @signature_request.cancel!
      redirect_to document_path(@document), notice: "Signature request cancelled."
    else
      redirect_to document_path(@document), alert: "Unable to cancel this signature request."
    end
  end

  def resend
    if @signature_request.send_signature_request!
      redirect_to document_path(@document), notice: "Signature request resent."
    else
      redirect_to document_path(@document), alert: "Unable to resend this signature request."
    end
  end

  def void
    if @signature_request.void!(current_user)
      redirect_to document_path(@document), notice: "Signature request voided."
    else
      redirect_to document_path(@document), alert: "Unable to void this signature request."
    end
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def set_signature_request
    @signature_request = @document.signature_requests.find(params[:id])
  end

  def check_document_access
    unless @document.can_access?(current_user)
      flash[:alert] = "You don't have permission to access this document."
      redirect_to documents_path
    end
  end

  def signature_request_params
    params.require(:signature_request).permit(
      :signer_email, :signer_name, :message, :expires_at
    )
  end

  # Sync fields from the JSON blob the Stimulus controller manages
  def sync_fields_from_json
    fields_json = params[:fields_json]
    return if fields_json.blank?

    begin
      fields_data = JSON.parse(fields_json)
    rescue JSON::ParserError
      return
    end

    # Replace all existing fields with the new set
    @signature_request.signature_fields.destroy_all

    fields_data.each do |fd|
      @signature_request.signature_fields.build(
        page_number: fd["page_number"],
        x_percent: fd["x_percent"],
        y_percent: fd["y_percent"],
        width_percent: fd["width_percent"],
        height_percent: fd["height_percent"],
        field_type: fd["field_type"],
        required: fd["required"] != false,
        position: fd["position"],
        label: fd["label"]
      )
    end
  end
end
