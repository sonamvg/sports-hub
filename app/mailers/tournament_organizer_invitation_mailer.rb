class TournamentOrganizerInvitationMailer < ApplicationMailer
  def invite
    @invitation = params[:invitation]
    @tournament = @invitation.tournament
    @signup_url = organizer_signup_url

    mail(to: @invitation.email, subject: "Organizer invite for #{@tournament.name}")
  end

  private

  def organizer_signup_url
    options = Rails.application.config.action_mailer.default_url_options || {}
    host_options = options.presence || { host: "127.0.0.1", port: 3000 }

    new_user_url(
      host_options.merge(
        account_type: "organizer",
        invited_email: @invitation.email,
        return_to: edit_tournament_path(@tournament)
      )
    )
  end
end
