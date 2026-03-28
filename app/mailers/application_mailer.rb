class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Pact <notifications@pactapp.io>")
  layout "mailer"

  after_action :add_list_unsubscribe

  private

  def add_list_unsubscribe
    headers["List-Unsubscribe"] = "<mailto:notifications@pactapp.io?subject=Unsubscribe>"
  end
end
