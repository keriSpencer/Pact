class WelcomeMailer < ApplicationMailer
  def welcome(user)
    @user = user
    @organization = user.organization

    mail(
      to: user.email,
      subject: "Welcome to Pact — a note from the founders",
      from: "Alex & Keri Spencer <notifications@pactapp.io>"
    )
  end
end
