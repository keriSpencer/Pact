module Api
  module V1
    class FoldersController < BaseController
      def index
        folders = Folder.visible_to(current_user).order(:path)
        render json: folders.map { |f| folder_json(f) }
      end

      def show
        folder = Folder.find(params[:id])
        unless folder.can_access?(current_user)
          return render_error("Access denied", status: :forbidden)
        end

        documents = folder.documents.active.visible_to(current_user).order(:name)
        render json: folder_json(folder).merge(
          documents: documents.map { |d| document_json(d) }
        )
      end

      def create
        folder = Folder.new(folder_params)
        folder.user = current_user
        folder.organization = current_organization

        if folder.save
          render json: folder_json(folder), status: :created
        else
          render_error(folder.errors.full_messages.join(", "))
        end
      end

      private

      def folder_params
        params.permit(:name, :parent_id, :visibility)
      end

      def folder_json(folder)
        {
          id: folder.id,
          name: folder.name,
          path: folder.path,
          parent_id: folder.parent_id,
          document_count: folder.document_count,
          created_at: folder.created_at,
          updated_at: folder.updated_at
        }
      end

      def document_json(doc)
        {
          id: doc.id,
          name: doc.name,
          file_hash: doc.file_hash,
          file_size: doc.file_size,
          content_type: doc.content_type,
          status: doc.status,
          updated_at: doc.updated_at,
          created_at: doc.created_at
        }
      end
    end
  end
end
