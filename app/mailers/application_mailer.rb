class ApplicationMailer < ActionMailer::Base
  default from: "Pact <notifications@pactapp.com>"
  layout "mailer"
end
