module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user, :current_organization
  end

  private

  def authenticate_api!
    token = extract_bearer_token
    unless token
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    user = User.find_by(api_token: token)
    unless user&.active_for_authentication?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    @current_user = user
    @current_organization = user.organization
    Current.user = user
    Current.organization = user.organization
    switch_to_tenant_schema
  end

  def extract_bearer_token
    header = request.headers["Authorization"]
    header&.match(/\ABearer (.+)\z/)&.[](1)
  end

  def switch_to_tenant_schema
    return unless current_organization&.respond_to?(:schema_name)
    return unless current_organization.schema_name.present?
    return unless ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")

    ActiveRecord::Base.connection.execute(
      "SET search_path TO #{ActiveRecord::Base.connection.quote_column_name(current_organization.schema_name)}, public"
    )
  end

  def reset_tenant_schema
    return unless ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
    ActiveRecord::Base.connection.execute("SET search_path TO public")
  end
end
