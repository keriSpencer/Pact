module Api
  module V1
    class BaseController < ActionController::API
      include ApiAuthenticatable

      before_action :authenticate_api!
      after_action :reset_tenant_schema

      private

      def render_error(message, status: :unprocessable_entity)
        render json: { error: message }, status: status
      end

      def render_not_found
        render json: { error: "Not found" }, status: :not_found
      end
    end
  end
end
