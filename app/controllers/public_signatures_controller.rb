class PublicSignaturesController < ApplicationController
  skip_before_action :ensure_authenticated
  skip_before_action :set_current_organization

  layout "signing"

  before_action :set_signature_request

  def show
    @signature_request.mark_as_viewed!
    @fields = @signature_request.signature_fields.includes(:completion).order(:position)
    auto_complete_pre_fillable_fields
  end

  def sign
    if @signature_request.sign!(
      signature_data: params[:signature_data],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
      redirect_to success_signature_path(@signature_request.signature_token)
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
      if params[:field_id].present?
        field = @signature_request.signature_fields.find(params[:field_id])
        field.complete!(
          artifact: artifact,
          signer_email: @signature_request.signer_email,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        ) unless field.completed?
      end
      redirect_to signature_path(@signature_request.signature_token), notice: "Captured successfully."
    else
      redirect_to signature_path(@signature_request.signature_token), alert: "Failed to capture."
    end
  end

  def complete_field
    field = @signature_request.signature_fields.find(params[:field_id])

    if params[:artifact_data].present? && field.text_input_type? || field.checkable?
      # For text-like and checkbox fields, create artifact and complete in one step
      artifact = SignatureArtifact.find_or_create_for(
        signature_request: @signature_request,
        signer_email: @signature_request.signer_email,
        artifact_type: field.field_type,
        artifact_data: params[:artifact_data],
        capture_method: "typed",
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
    else
      artifact = @signature_request.signature_artifacts.find(params[:artifact_id])
    end

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
      redirect_to success_signature_path(@signature_request.signature_token)
    else
      flash.now[:alert] = "Please complete all required fields before submitting."
      @fields = @signature_request.signature_fields.order(:position)
      render :show, status: :unprocessable_entity
    end
  end

  def success
    unless @signature_request.signed?
      redirect_to signature_path(@signature_request.signature_token)
    end
  end

  private

  def set_signature_request
    @signature_request = SignatureRequest.find_by!(signature_token: params[:signature_token])
  end

  def auto_complete_pre_fillable_fields
    return unless @signature_request.can_sign?

    @fields.each do |field|
      next if field.completed?
      next unless field.pre_fillable?

      data = case field.field_type
      when "name"
        @signature_request.signer_name.presence
      when "email"
        @signature_request.signer_email.presence
      when "date"
        Time.current.strftime("%B %d, %Y at %l:%M %p")
      end

      next unless data

      artifact = SignatureArtifact.find_or_create_for(
        signature_request: @signature_request,
        signer_email: @signature_request.signer_email,
        artifact_type: field.field_type,
        artifact_data: data,
        capture_method: "typed",
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      if artifact.persisted?
        field.complete!(
          artifact: artifact,
          signer_email: @signature_request.signer_email,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )
      end
    end

    # Reload fields to reflect auto-completions
    @fields = @signature_request.signature_fields.includes(:completion).order(:position)
  end
end
