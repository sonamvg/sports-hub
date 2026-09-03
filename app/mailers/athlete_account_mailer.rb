class AthleteAccountMailer < ApplicationMailer
  def academy_created_account
    @athlete = params[:athlete]
    @academy = params[:academy]
    @password = params[:password]
    @login_url = login_url(default_url_options)

    mail(to: @athlete.user.email, subject: "Your PodiumCircle athlete account")
  end

  def academy_removed
    @athlete = params[:athlete]
    @academy = params[:academy]
    @login_url = login_url(default_url_options)

    mail(to: @athlete.user.email, subject: "#{@academy.name} removed your academy link")
  end

  private

  def default_url_options
    options = Rails.application.config.action_mailer.default_url_options || {}
    options.presence || { host: "127.0.0.1", port: 3000 }
  end
end
