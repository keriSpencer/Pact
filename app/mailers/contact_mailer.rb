class ContactMailer < ApplicationMailer
  skip_after_action :add_list_unsubscribe

  def contact_form(name:, email:, phone:, message:)
    @name = name
    @email = email
    @phone = phone
    @message = message

    mail(
      to: "alex@alexspencer.net",
      subject: "Pact — New inquiry from #{name}",
      reply_to: email
    )
  end
end
