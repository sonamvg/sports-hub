class PasswordMailer < ApplicationMailer
  def reset_instructions
    @user = params[:user]
    token = @user.generate_token_for(:password_reset)
    @reset_url = edit_password_reset_url(token: token, **default_url_options)

    mail(to: @user.email, subject: "Reset your PodiumCircle password")
  end

  private

  def default_url_options
    options = Rails.application.config.action_mailer.default_url_options || {}
    options.presence || { host: "127.0.0.1", port: 3000 }
  end
end
