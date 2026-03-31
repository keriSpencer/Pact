module Api
  module V1
    class SyncController < BaseController
      def status
        folder = Folder.find_by(id: params[:folder_id])
        unless folder&.can_access?(current_user)
          return render_error("Folder not found or access denied", status: :not_found)
        end

        folder_ids = collect_folder_ids(folder)
        since = params[:since].present? ? Time.parse(params[:since]) : nil

        documents = Document.where(folder_id: folder_ids)
                            .visible_to(current_user)

        if since
          active_docs = documents.active.where("documents.updated_at > ?", since)
          deleted_ids = documents.where(status: [:archived, :deleted])
                                .where("documents.updated_at > ?", since)
                                .pluck(:id)
        else
          active_docs = documents.active
          deleted_ids = []
        end

        render json: {
          server_time: Time.current.iso8601,
          folder: { id: folder.id, name: folder.name, path: folder.path },
          documents: active_docs.map { |doc| sync_document_json(doc) },
          deleted_ids: deleted_ids
        }
      end

      private

      def collect_folder_ids(folder)
        ids = [folder.id]
        folder.subfolders.each do |sub|
          ids.concat(collect_folder_ids(sub))
        end
        ids
      end

      def sync_document_json(doc)
        {
          id: doc.id,
          name: doc.name,
          file_hash: doc.file_hash,
          file_size: doc.file_size,
          content_type: doc.content_type,
          folder_id: doc.folder_id,
          updated_at: doc.updated_at.iso8601,
          created_at: doc.created_at.iso8601
        }
      end
    end
  end
end
