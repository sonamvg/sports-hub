class TournamentOrganizerInvitationsController < ApplicationController
  before_action :require_user
  before_action :set_tournament
  before_action :require_tournament_manager

  def create
    @invitation = @tournament.tournament_organizer_invitations.build(invitation_params)
    @invitation.invited_by = current_user

    if @invitation.save
      TournamentOrganizerInvitationMailer.with(invitation: @invitation).invite.deliver_later
      redirect_to edit_tournament_path(@tournament), notice: "Organizer invitation sent."
    else
      redirect_to edit_tournament_path(@tournament), alert: @invitation.errors.full_messages.to_sentence
    end
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def require_tournament_manager
    raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@tournament)
  end

  def invitation_params
    params.require(:tournament_organizer_invitation).permit(:email)
  end
end
