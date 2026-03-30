class PublicSignaturesController < ApplicationController
  skip_before_action :ensure_authenticated
  skip_before_action :set_current_organization

  rate_limit to: 60, within: 1.minute, by: -> { request.remote_ip }, with: -> { head :too_many_requests }

  layout "signing"

  before_action :set_signature_request

  def show
    @signature_request.mark_as_viewed!
    @fields = @signature_request.signature_fields.includes(:completion).order(:position)

    # Multi-signer: check if it's this signer's turn (sequential mode)
    @waiting = false
    if @signature_request.signing_envelope.present? && @signature_request.signing_role.present?
      envelope = @signature_request.signing_envelope
      if envelope.sequential? && envelope.active? && !envelope.can_signer_sign?(@signature_request.signing_role)
        @waiting = true
      end

      # Collect other signers' completed fields for overlay display
      @other_signer_fields = []
      envelope.signature_requests.where.not(id: @signature_request.id).each do |other_req|
        other_req.signature_fields.includes(:completion, :signing_role).where.not(signing_role: nil).each do |field|
          next unless field.completed?
          @other_signer_fields << {
            page: field.page_number,
            x: field.x_percent,
            y: field.y_percent,
            width: field.width_percent,
            height: field.height_percent,
            type: field.field_type,
            label: field.label,
            signer_name: other_req.signer_display_name,
            role_color: field.signing_role&.color || '#9CA3AF',
            completed: true,
            artifact_value: sanitized_artifact_value(field)
          }
        end
      end
    end

    auto_complete_pre_fillable_fields unless @waiting
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
      respond_to do |format|
        format.json { render json: { success: true, artifact_id: artifact.id } }
        format.html { redirect_to signature_path(@signature_request.signature_token), notice: "Captured successfully." }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, error: "Failed to capture" }, status: :unprocessable_entity }
        format.html { redirect_to signature_path(@signature_request.signature_token), alert: "Failed to capture." }
      end
    end
  end

  def complete_field
    field = @signature_request.signature_fields.find(params[:field_id])

    if field.completed?
      respond_to do |format|
        format.json { render json: { success: true, already_completed: true } }
        format.html { redirect_to signature_path(@signature_request.signature_token), notice: "Field already completed." }
      end
      return
    end

    artifact = SignatureArtifact.find_or_create_for(
      signature_request: @signature_request,
      signer_email: @signature_request.signer_email,
      artifact_type: params[:artifact_type] || field.field_type,
      artifact_data: params[:artifact_data],
      capture_method: params[:capture_method] || "typed",
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if field.complete!(
      artifact: artifact,
      signer_email: @signature_request.signer_email,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
      respond_to do |format|
        format.json { render json: { success: true, field_id: field.id } }
        format.html { redirect_to signature_path(@signature_request.signature_token), notice: "Field completed." }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, error: "Failed to complete field" }, status: :unprocessable_entity }
        format.html { redirect_to signature_path(@signature_request.signature_token), alert: "Unable to complete this field." }
      end
    end
  end

  def reset_field
    field = @signature_request.signature_fields.find(params[:field_id])

    if field.reset!
      respond_to do |format|
        format.json { render json: { success: true, field_id: field.id } }
        format.html { redirect_to signature_path(@signature_request.signature_token), notice: "Field reset." }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, error: "Unable to reset field" }, status: :unprocessable_entity }
        format.html { redirect_to signature_path(@signature_request.signature_token), alert: "Unable to reset this field." }
      end
    end
  end

  def finalize
    # Complete date fields NOW with the actual signing timestamp
    complete_date_fields_at_signing_time

    if @signature_request.finalize_signing!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
      respond_to do |format|
        format.json { render json: { success: true, redirect_url: success_signature_path(@signature_request.signature_token) } }
        format.html { redirect_to success_signature_path(@signature_request.signature_token) }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, error: "Not all required fields are completed" }, status: :unprocessable_entity }
        format.html do
          flash.now[:alert] = "Please complete all required fields before submitting."
          @fields = @signature_request.signature_fields.order(:position)
          render :show, status: :unprocessable_entity
        end
      end
    end
  end

  def success
    unless @signature_request.signed?
      redirect_to signature_path(@signature_request.signature_token)
    end
  end

  private

  # Never expose drawn signature images to other signers — privacy/security
  def sanitized_artifact_value(field)
    artifact = field.completion&.signature_artifact
    return nil unless artifact

    data = artifact.typed_text.presence || artifact.artifact_data
    return nil unless data

    # If it's a drawn image, don't expose it — show placeholder text
    if data.start_with?("data:image/")
      nil  # The JS will show "Signed by [name]" instead
    else
      data
    end
  end

  def set_signature_request
    @signature_request = SignatureRequest.find_by!(signature_token: params[:signature_token])
  end

  def complete_date_fields_at_signing_time
    signing_timestamp = Time.current.strftime("%B %d, %Y at %l:%M %p")

    @signature_request.signature_fields.where(field_type: "date").each do |field|
      next if field.completed?

      artifact = SignatureArtifact.find_or_create_for(
        signature_request: @signature_request,
        signer_email: @signature_request.signer_email,
        artifact_type: "date",
        artifact_data: signing_timestamp,
        capture_method: "auto",
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      field.complete!(
        artifact: artifact,
        signer_email: @signature_request.signer_email,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      ) if artifact.persisted?
    end
  end

  def auto_complete_pre_fillable_fields
    return unless @signature_request.can_sign?

    @fields.each do |field|
      next if field.completed?
      next unless field.pre_fillable?

      # Don't auto-complete date fields — they get filled at submit time
      # so the timestamp reflects when the signer actually signs
      next if field.field_type == "date"

      data = case field.field_type
      when "name"
        @signature_request.signer_name.presence
      when "email"
        @signature_request.signer_email.presence
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
