module Api
  module V1
    class DocumentsController < BaseController
      before_action :set_document, only: [:show, :update, :destroy, :download]
      before_action :check_access, only: [:show, :update, :destroy, :download]

      def show
        render json: document_json(@document)
      end

      def create
        unless current_organization.can_create_document?
          return render_error("Document limit reached for your plan", status: :forbidden)
        end

        document = Document.new(document_params)
        document.user = current_user
        document.organization = current_organization

        if document.save
          render json: document_json(document), status: :created
        else
          render_error(document.errors.full_messages.join(", "))
        end
      end

      def update
        if params[:file].present?
          @document.file.attach(params[:file])
        end

        if @document.update(update_params)
          render json: document_json(@document)
        else
          render_error(@document.errors.full_messages.join(", "))
        end
      end

      def destroy
        archived = !@document.safe_destroy!
        render json: { deleted: !archived, archived: archived }
      end

      def download
        unless @document.file.attached?
          return render_not_found
        end

        url = if @document.file.service.is_a?(ActiveStorage::Service::DiskService)
          Rails.application.routes.url_helpers.rails_blob_url(@document.file, disposition: "attachment", host: request.base_url)
        else
          @document.file.url(expires_in: 5.minutes)
        end

        render json: { download_url: url }
      end

      private

      def set_document
        @document = Document.find_by(id: params[:id])
        render_not_found unless @document
      end

      def check_access
        return unless @document
        unless @document.can_access?(current_user)
          render_error("Access denied", status: :forbidden)
        end
      end

      def document_params
        params.permit(:name, :description, :file, :folder_id, :contact_id, :visibility)
      end

      def update_params
        params.permit(:name, :description, :folder_id, :visibility)
      end

      def document_json(doc)
        {
          id: doc.id,
          name: doc.name,
          description: doc.description,
          file_hash: doc.file_hash,
          file_size: doc.file_size,
          content_type: doc.content_type,
          visibility: doc.visibility,
          status: doc.status,
          folder_id: doc.folder_id,
          version: doc.version,
          created_at: doc.created_at,
          updated_at: doc.updated_at
        }
      end
    end
  end
end
