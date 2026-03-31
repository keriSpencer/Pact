class SignatureTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document
  before_action :check_document_access
  before_action :set_template, only: [:destroy, :apply]

  def index
    @templates = @document.signature_templates.by_recent
    render json: @templates.map { |t|
      { id: t.id, name: t.name, description: t.description, use_count: t.use_count, fields_count: t.template_fields.count }
    }
  end

  def create
    @template = @document.signature_templates.build(template_params)
    @template.user = current_user
    @template.organization = current_organization

    if params[:fields].present?
      fields = params[:fields].is_a?(String) ? JSON.parse(params[:fields]) : params[:fields]
      fields.each do |fd|
        role_label = nil
        if fd["role_id"].present?
          role = SigningRole.find_by(id: fd["role_id"])
          role_label = role&.label
        end

        @template.template_fields.build(
          page_number: fd["page_number"],
          x_percent: fd["x_percent"],
          y_percent: fd["y_percent"],
          width_percent: fd["width_percent"],
          height_percent: fd["height_percent"],
          field_type: fd["field_type"],
          label: fd["label"],
          required: fd["required"] != false,
          position: fd["position"],
          role_label: role_label
        )
      end
    end

    if @template.save
      render json: { id: @template.id, name: @template.name, message: "Template saved." }, status: :created
    else
      render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    render json: { message: "Template deleted." }
  end

  def apply
    @template.increment_usage!

    respond_to do |format|
      format.json { render json: { fields: @template.fields_as_json } }
      format.html { apply_template_to_draft }
      format.turbo_stream { apply_template_to_draft }
    end
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def check_document_access
    unless @document.can_access?(current_user)
      flash[:alert] = "You don't have permission to access this document."
      redirect_to documents_path
    end
  end

  def set_template
    @template = @document.signature_templates.find(params[:id])
  end

  def template_params
    params.permit(:name, :description)
  end

  def apply_template_to_draft
    # Determine if we're in multi-signer (envelope) or single-signer mode
    envelope = nil
    roles = []

    if params[:signing_envelope_id].present?
      envelope = @document.signing_envelopes.find_by(id: params[:signing_envelope_id])
    end

    if envelope
      sr = envelope.signature_requests.where(status: :draft).first
      roles = envelope.signing_roles.in_order.to_a
      redirect_path = sr ? edit_document_signing_envelope_path(@document, envelope) : document_path(@document)
    else
      sr = @document.signature_requests.where(status: :draft).order(created_at: :desc).first
      # Check if the draft request belongs to an envelope
      if sr&.signing_envelope.present?
        envelope = sr.signing_envelope
        roles = envelope.signing_roles.in_order.to_a
        redirect_path = edit_document_signing_envelope_path(@document, envelope)
      else
        redirect_path = sr ? edit_document_signature_request_path(@document, sr) : document_path(@document)
      end
    end

    unless sr
      redirect_back fallback_location: document_path(@document), alert: "No draft request found."
      return
    end

    sr.signature_fields.destroy_all

    @template.template_fields.order(:position).each do |tf|
      # Match role by label if in multi-signer mode
      signing_role = nil
      if roles.any?
        if tf.role_label.present?
          signing_role = roles.find { |r| r.label == tf.role_label }
        end
        signing_role ||= roles.first
      end

      sr.signature_fields.create!(
        page_number: tf.page_number,
        x_percent: tf.x_percent,
        y_percent: tf.y_percent,
        width_percent: tf.width_percent,
        height_percent: tf.height_percent,
        field_type: tf.field_type,
        label: tf.label,
        required: tf.required,
        position: tf.position,
        signing_role: signing_role
      )
    end

    redirect_to redirect_path, notice: "Template '#{@template.name}' applied."
  end
end
