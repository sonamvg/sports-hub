class OrganizersController < ApplicationController
  before_action :require_super_admin, only: %i[approve reject]
  before_action :set_organizer, only: %i[approve reject]

  def index
    @verified_organizers = User.verified_organizers.includes(:organized_tournaments, :tournament_organizers).order(:name)
    @pending_organizers = super_admin? ? User.pending_organizers.order(:created_at) : User.none
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
