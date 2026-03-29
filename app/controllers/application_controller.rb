class ApplicationController < ActionController::Base
  include Authorization
  include OrganizationScoped

  before_action :set_current_user
  before_action :require_subscription!

  allow_browser versions: :modern

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  private

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def require_subscription!
    return unless user_signed_in?
    return if devise_controller?
    return if self.class.name.in?(%w[PagesController SubscriptionsController StripeWebhooksController])
    return unless current_organization&.needs_subscription?

    redirect_to billing_path, alert: "Please select a plan to get started."
  end

  def set_current_user
    Current.user = current_user if user_signed_in?
  end

  def handle_standard_error(exception)
    Rails.logger.error "Unhandled error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")

    respond_to do |format|
      format.html do
        flash[:alert] = "An error occurred. Please try again or contact support if the problem persists."
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: "Internal server error" }, status: 500 }
      format.turbo_stream { render turbo_stream: turbo_stream.prepend("flash", partial: "shared/flash", locals: { message: "An error occurred", type: "alert" }) }
    end
  end

  def handle_not_found(exception)
    respond_to do |format|
      format.html do
        flash[:alert] = "The requested item was not found."
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: "Not found" }, status: 404 }
    end
  end

  def handle_parameter_missing(exception)
    respond_to do |format|
      format.html do
        flash[:alert] = "Required information is missing. Please check your input."
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: "Missing parameter: #{exception.param}" }, status: 400 }
    end
  end
end
