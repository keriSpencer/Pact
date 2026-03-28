class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Pact <notifications@pactapp.io>")
  layout "mailer"
end
