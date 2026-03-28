class PagesController < ApplicationController
  skip_before_action :ensure_authenticated
  layout "landing"

  def home
    redirect_to dashboard_path if user_signed_in?
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
