class PagesController < ApplicationController
  skip_before_action :ensure_authenticated
  layout "landing"

  def home
    redirect_to dashboard_path if user_signed_in?
  end

  skip_before_action :require_subscription!, only: :launch
  skip_before_action :set_current_user, only: :launch
  skip_before_action :allow_browser, only: :launch

  def launch
    redirect_to user_signed_in? ? dashboard_path : new_user_session_path, allow_other_host: true
  end

  def contact
  end

  def submit_contact
    name = params[:name].to_s.strip
    email = params[:email].to_s.strip

    if name.blank? || email.blank?
      flash.now[:alert] = "Please provide your name and email."
      render :contact, status: :unprocessable_entity
      return
    end

    ContactMailer.contact_form(
      name: name,
      email: email,
      phone: params[:phone].to_s.strip,
      message: params[:message].to_s.strip
    ).deliver_later

    redirect_to contact_us_path, notice: "Thanks for reaching out! We'll be in touch soon."
  end
end
