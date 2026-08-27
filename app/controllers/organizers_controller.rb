class OrganizersController < ApplicationController
  before_action :require_user, only: %i[profile]
  before_action :require_super_admin, only: %i[approve reject]
  before_action :set_organizer, only: %i[approve reject]

  def index
    @verified_organizers = User.verified_organizers.includes(:organized_tournaments, :tournament_organizers).order(:name)
    @pending_organizers = super_admin? ? User.pending_organizers.order(:created_at) : User.none
  end

  def profile
    unless current_user&.can_organize_tournaments?
      redirect_to organizers_path, alert: "Create an organizer account to access an organizer profile."
      return
    end

    @organizer = current_user
    @owned_tournaments = @organizer.organized_tournaments.order(created_at: :desc)
    @collaborating_tournaments = @organizer.collaborating_tournaments.where.not(organizer_id: @organizer.id).distinct.order(start_date: :desc)
  end

  def approve
    @organizer.verify_organizer!(reviewer: current_user)
    redirect_to organizers_path, notice: "Organizer verified."
  end

  def reject
    @organizer.reject_organizer!(reviewer: current_user)
    redirect_to organizers_path, notice: "Organizer rejected."
  end

  private

  def set_organizer
    @organizer = User.organizer.find(params[:id])
  end
end
