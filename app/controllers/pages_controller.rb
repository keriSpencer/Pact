class PagesController < ApplicationController
  skip_before_action :ensure_authenticated
  layout "landing"

  def home
    redirect_to dashboard_path if user_signed_in?
  end

  def launch
    redirect_to user_signed_in? ? dashboard_path : new_user_session_path
  end

  def contact
  end

  def sync
  end

  def download_pactsync
    path = Rails.root.join("public", "PactSync-1.0.0.dmg")
    send_file path, filename: "PactSync-1.0.0.dmg", type: "application/x-apple-diskimage"
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
