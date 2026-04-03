class SigningEnvelopesController < ApplicationController
  before_action :set_document
  before_action :set_envelope, only: [:edit, :update, :add_role, :remove_role, :send_envelope, :void, :discard_draft]
  before_action :check_document_access

  def new
    @envelope = @document.signing_envelopes.create!(
      requester: current_user,
      status: :draft,
      signing_mode: :parallel
    )

    # Create one default role, pre-filling from params if provided
    @envelope.signing_roles.create!(
      label: "Signer 1",
      color: SigningRole::COLORS[0],
      signing_order: 0,
      signer_email: params[:signer_email].presence,
      signer_name: params[:signer_name].presence
    )

    # Create a draft signature request to hold fields during editing
    @draft_request = @document.signature_requests.create!(
      requester: current_user,
      status: :draft,
      signer_email: params[:signer_email] || "",
      signing_envelope: @envelope
    )

    redirect_to edit_document_signing_envelope_path(@document, @envelope)
  end

  def edit
    @roles = @envelope.signing_roles.in_order
    @draft_request = @envelope.signature_requests.where(status: :draft).first
    @signature_fields = @draft_request&.signature_fields&.order(:position) || []
  end

  def update
    @roles = @envelope.signing_roles.in_order
    @draft_request = @envelope.signature_requests.where(status: :draft).first

    # Update envelope attributes
    @envelope.assign_attributes(envelope_params)

    # Update role details
    sync_roles_from_params

    # Sync fields from JSON onto the draft request
    sync_fields_from_json if @draft_request

    if params[:send_envelope].present?
      # Validate all non-self-signer roles have emails
      missing_emails = @envelope.signing_roles.reload.where(is_self_signer: false).select { |r| r.signer_email.blank? }
      if missing_emails.any?
        flash.now[:alert] = "All signers must have email addresses before sending."
        @roles = @envelope.signing_roles.reload.in_order
        @signature_fields = @draft_request&.signature_fields&.reload&.order(:position) || []
        render :edit, status: :unprocessable_entity
        return
      end

      # Check every signer role has at least one field assigned
      if @draft_request
        roles_without_fields = @envelope.signing_roles.reload.select do |role|
          @draft_request.signature_fields.where(signing_role: role).none?
        end

        if roles_without_fields.any?
          names = roles_without_fields.map(&:display_name).join(", ")
          flash.now[:alert] = "#{names} #{roles_without_fields.count == 1 ? 'has' : 'have'} no fields assigned. Assign fields or remove #{roles_without_fields.count == 1 ? 'this signer' : 'these signers'}."
          @roles = @envelope.signing_roles.reload.in_order
          @signature_fields = @draft_request.signature_fields.reload.order(:position)
          render :edit, status: :unprocessable_entity
          return
        end
      end

      if @envelope.save
        # Auto-complete self-signer fields before activation
        auto_complete_self_signer_fields

        @envelope.activate!
        # Clean up the draft request (fields have been moved to per-signer requests)
        @draft_request&.destroy if @draft_request&.signature_fields&.reload&.empty?

        non_self_roles = @envelope.signing_roles.where(is_self_signer: false)
        notice_msg = if non_self_roles.count == 1
          "Signature request sent to #{non_self_roles.first.signer_name.presence || non_self_roles.first.signer_email}."
        else
          "Sent to #{non_self_roles.count} signers."
        end
        redirect_to document_path(@document), notice: notice_msg
      else
        flash.now[:alert] = @envelope.errors.full_messages.join(", ")
        @roles = @envelope.signing_roles.reload.in_order
        @signature_fields = @draft_request&.signature_fields&.reload&.order(:position) || []
        render :edit, status: :unprocessable_entity
      end
    else
      if @envelope.save
        redirect_to edit_document_signing_envelope_path(@document, @envelope), notice: "Draft saved."
      else
        @signature_fields = @draft_request&.signature_fields&.order(:position) || []
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def add_role
    # Save current form state first
    sync_roles_from_params
    @draft_request = @envelope.signature_requests.where(status: :draft).first
    sync_fields_from_json if @draft_request
    @envelope.assign_attributes(envelope_params)
    @envelope.save

    next_order = @envelope.signing_roles.maximum(:signing_order).to_i + 1
    color_index = @envelope.signing_roles.count % SigningRole::COLORS.length
    @envelope.signing_roles.create!(
      label: "Signer #{@envelope.signing_roles.count + 1}",
      color: SigningRole::COLORS[color_index],
      signing_order: next_order
    )

    redirect_to edit_document_signing_envelope_path(@document, @envelope)
  end

  def remove_role
    # Save current form state first
    sync_roles_from_params
    @draft_request = @envelope.signature_requests.where(status: :draft).first
    sync_fields_from_json if @draft_request
    @envelope.assign_attributes(envelope_params)
    @envelope.save

    role = @envelope.signing_roles.find(params[:role_id])
    if @envelope.signing_roles.count > 1
      if @draft_request
        @draft_request.signature_fields.where(signing_role: role).destroy_all
      end
      role.destroy
      redirect_to edit_document_signing_envelope_path(@document, @envelope)
    else
      redirect_to edit_document_signing_envelope_path(@document, @envelope), alert: "Must have at least one signer."
    end
  end

  def send_envelope
    # This action is called from the form via the send_envelope button
    # The update action handles it via params[:send_envelope]
    params[:send_envelope] = "1"
    update
  end

  def discard_draft
    if @envelope.draft?
      @envelope.signature_requests.destroy_all
      @envelope.signing_roles.destroy_all
      @envelope.destroy
      redirect_to document_path(@document), notice: "Draft discarded."
    else
      redirect_to document_path(@document), alert: "Only drafts can be discarded."
    end
  end

  def void
    if @envelope.void!(current_user)
      redirect_to document_path(@document), notice: "Signing envelope voided."
    else
      redirect_to document_path(@document), alert: "Unable to void this envelope."
    end
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def set_envelope
    @envelope = @document.signing_envelopes.find(params[:id])
  end

  def check_document_access
    unless @document.can_access?(current_user)
      flash[:alert] = "You don't have permission to access this document."
      redirect_to documents_path
    end
  end

  def envelope_params
    params.permit(:signing_mode, :message)
  end

  def sync_roles_from_params
    roles_data = params[:roles]
    return unless roles_data.is_a?(ActionController::Parameters) || roles_data.is_a?(Hash)

    roles_data.each do |role_id, role_attrs|
      role = @envelope.signing_roles.find_by(id: role_id)
      next unless role

      role.update(
        label: role_attrs[:label],
        signer_email: role_attrs[:is_self_signer] == "1" ? nil : role_attrs[:signer_email],
        signer_name: role_attrs[:is_self_signer] == "1" ? nil : role_attrs[:signer_name],
        is_self_signer: role_attrs[:is_self_signer] == "1"
      )
    end
  end

  def sync_fields_from_json
    fields_json = params[:fields_json]
    return if fields_json.blank?

    begin
      fields_data = JSON.parse(fields_json)
    rescue JSON::ParserError
      return
    end

    # Replace all existing fields with the new set
    @draft_request.signature_fields.destroy_all

    fields_data.each do |fd|
      # Map client-side role_id to an actual SigningRole
      signing_role = nil
      if fd["role_id"].present?
        signing_role = @envelope.signing_roles.find_by(id: fd["role_id"])
      end
      # Default to first role if none specified
      signing_role ||= @envelope.signing_roles.in_order.first

      @draft_request.signature_fields.build(
        page_number: fd["page_number"],
        x_percent: fd["x_percent"],
        y_percent: fd["y_percent"],
        width_percent: fd["width_percent"],
        height_percent: fd["height_percent"],
        field_type: fd["field_type"],
        required: fd["required"] != false,
        position: fd["position"],
        label: fd["label"],
        signing_role: signing_role
      )
    end

    @draft_request.save!
  end

  def auto_complete_self_signer_fields
    draft_request = @envelope.signature_requests.where(status: :draft).first
    return unless draft_request

    @envelope.signing_roles.where(is_self_signer: true).each do |role|
      role_fields = draft_request.signature_fields.where(signing_role: role)
      role_fields.each do |field|
        next if field.completed?

        # Check sources in order: editor self-sign data, saved profile signature, typed fallback
        self_sign_data = find_self_sign_data_for_field(field)

        artifact_data = nil
        capture_method = "typed"

        if self_sign_data.present? && self_sign_data["artifact_data"].present?
          # 1. Use data drawn in the editor
          artifact_data = self_sign_data["artifact_data"]
          capture_method = self_sign_data["capture_method"] || "drawn"
        elsif field.field_type == "signature" && current_user.has_saved_signature?
          # 2. Use saved signature from profile
          artifact_data = current_user.saved_signature
          capture_method = current_user.saved_signature.start_with?("data:image") ? "drawn" : "typed"
        elsif field.field_type == "initials" && current_user.has_saved_initials?
          # 3. Use saved initials from profile
          artifact_data = current_user.saved_initials
          capture_method = current_user.saved_initials.start_with?("data:image") ? "drawn" : "typed"
        else
          # 4. Fallback to typed text
          artifact_data = case field.field_type
          when "signature" then current_user.full_name
          when "initials" then current_user.full_name.split.map { |n| n[0] }.join
          when "date" then Time.current.strftime("%B %d, %Y at %l:%M %p")
          when "name" then current_user.full_name
          when "email" then current_user.email
          else "[Self-signed]"
          end
        end

        artifact = SignatureArtifact.find_or_create_for(
          signature_request: draft_request,
          signer_email: current_user.email,
          artifact_type: field.field_type,
          artifact_data: artifact_data,
          capture_method: capture_method
        )

        field.complete!(
          artifact: artifact,
          signer_email: current_user.email
        ) if artifact.persisted?
      end
    end
  end

  def find_self_sign_data_for_field(field)
    return nil unless params[:self_sign_data].present?
    begin
      data = JSON.parse(params[:self_sign_data])
      # Match by field position since field IDs are created during sync
      data[field.position.to_s]
    rescue JSON::ParserError
      nil
    end
  end
end
