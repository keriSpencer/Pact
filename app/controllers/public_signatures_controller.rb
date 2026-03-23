class PublicSignaturesController < ApplicationController
  skip_before_action :ensure_authenticated
  skip_before_action :set_current_organization

  layout "signing"

  before_action :set_signature_request

  def show
    @signature_request.mark_as_viewed!
    @fields = @signature_request.signature_fields.order(:position)
  end

  def sign
    if @signature_request.sign!(
      signature_data: params[:signature_data],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
      redirect_to signature_path(@signature_request.signature_token), notice: "Document signed successfully. Thank you!"
    else
      flash.now[:alert] = "Unable to sign this document."
      @fields = @signature_request.signature_fields.order(:position)
      render :show, status: :unprocessable_entity
    end
  end

  def decline
    if @signature_request.decline!(
      reason: params[:decline_reason],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
      redirect_to signature_path(@signature_request.signature_token), notice: "You have declined to sign this document."
    else
      flash.now[:alert] = "Unable to process your request."
      @fields = @signature_request.signature_fields.order(:position)
      render :show, status: :unprocessable_entity
    end
  end

  def capture_artifact
    artifact = SignatureArtifact.find_or_create_for(
      signature_request: @signature_request,
      signer_email: @signature_request.signer_email,
      artifact_type: params[:artifact_type] || "signature",
      artifact_data: params[:artifact_data],
      capture_method: params[:capture_method] || "typed",
      typed_text: params[:typed_text],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if artifact.persisted?
      redirect_to signature_path(@signature_request.signature_token), notice: "Captured successfully."
    else
      redirect_to signature_path(@signature_request.signature_token), alert: "Failed to capture."
    end
  end

  def complete_field
    field = @signature_request.signature_fields.find(params[:field_id])
    artifact = @signature_request.signature_artifacts.find(params[:artifact_id])

    if field.complete!(
      artifact: artifact,
      signer_email: @signature_request.signer_email,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
      redirect_to signature_path(@signature_request.signature_token), notice: "Field completed."
    else
      redirect_to signature_path(@signature_request.signature_token), alert: "Unable to complete this field."
    end
  end

  def reset_field
    field = @signature_request.signature_fields.find(params[:field_id])

    if field.reset!
      redirect_to signature_path(@signature_request.signature_token), notice: "Field reset."
    else
      redirect_to signature_path(@signature_request.signature_token), alert: "Unable to reset this field."
    end
  end

  def finalize
    if @signature_request.finalize_signing!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
      redirect_to signature_path(@signature_request.signature_token), notice: "Document signed successfully. Thank you!"
    else
      flash.now[:alert] = "Please complete all required fields before submitting."
      @fields = @signature_request.signature_fields.order(:position)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_signature_request
    @signature_request = SignatureRequest.find_by!(signature_token: params[:signature_token])
  end
end
