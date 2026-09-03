class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "no-reply@podiumcircle.com") }
  layout "mailer"
end
