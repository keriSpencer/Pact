module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_api!, only: [:login]

      def login
        user = User.find_by("LOWER(email) = ?", params[:email]&.downcase)

        unless user&.valid_password?(params[:password])
          render json: { error: "Invalid email or password" }, status: :unauthorized
          return
        end

        unless user.active_for_authentication?
          render json: { error: "Account is inactive" }, status: :unauthorized
          return
        end

        user.generate_api_token!

        render json: {
          token: user.api_token,
          user: {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            display_name: user.display_name,
            organization: user.organization.name
          }
        }
      end

      def logout
        current_user.revoke_api_token!
        render json: { message: "Logged out" }
      end
    end
  end
end
