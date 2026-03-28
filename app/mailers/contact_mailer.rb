class ContactMailer < ApplicationMailer
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
