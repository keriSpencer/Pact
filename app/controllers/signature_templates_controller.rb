class SignatureTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document
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
        @template.template_fields.build(
          page_number: fd["page_number"],
          x_percent: fd["x_percent"],
          y_percent: fd["y_percent"],
          width_percent: fd["width_percent"],
          height_percent: fd["height_percent"],
          field_type: fd["field_type"],
          label: fd["label"],
          required: fd["required"] != false,
          position: fd["position"]
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
      format.html do
        # Find the latest draft signature request for this document, or redirect back
        sr = @document.signature_requests.where(status: :draft).order(created_at: :desc).first
        if sr
          # Apply template fields to the signature request
          sr.signature_fields.destroy_all
          @template.template_fields.each do |tf|
            sr.signature_fields.create!(
              page_number: tf.page_number,
              x_percent: tf.x_percent,
              y_percent: tf.y_percent,
              width_percent: tf.width_percent,
              height_percent: tf.height_percent,
              field_type: tf.field_type,
              label: tf.label,
              required: tf.required,
              position: tf.position
            )
          end
          redirect_to edit_document_signature_request_path(@document, sr), notice: "Template '#{@template.name}' applied."
        else
          redirect_back fallback_location: document_path(@document), notice: "Template applied."
        end
      end
      format.turbo_stream do
        sr = @document.signature_requests.where(status: :draft).order(created_at: :desc).first
        if sr
          sr.signature_fields.destroy_all
          @template.template_fields.each do |tf|
            sr.signature_fields.create!(
              page_number: tf.page_number,
              x_percent: tf.x_percent,
              y_percent: tf.y_percent,
              width_percent: tf.width_percent,
              height_percent: tf.height_percent,
              field_type: tf.field_type,
              label: tf.label,
              required: tf.required,
              position: tf.position
            )
          end
          redirect_to edit_document_signature_request_path(@document, sr), notice: "Template '#{@template.name}' applied."
        else
          redirect_back fallback_location: document_path(@document), notice: "Template applied."
        end
      end
    end
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def set_template
    @template = @document.signature_templates.find(params[:id])
  end

  def template_params
    params.permit(:name, :description)
  end
end
