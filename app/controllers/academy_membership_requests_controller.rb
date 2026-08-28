class AcademyMembershipRequestsController < ApplicationController
  before_action :require_user
  before_action :set_academy
  before_action :require_academy_manager
  before_action :set_membership_request

  def approve
    @membership_request.approve!(reviewer: current_user)
    redirect_to @academy, notice: "Athlete added to academy."
  end

  def reject
    @membership_request.reject!(reviewer: current_user)
    redirect_to @academy, notice: "Athlete request rejected."
  end

  private

  def set_academy
    @academy = Academy.find(params[:academy_id])
  end

  def require_academy_manager
    raise ActiveRecord::RecordNotFound unless can_manage_academy?(@academy)
  end

  def set_membership_request
    @membership_request = @academy.academy_membership_requests.pending.find(params[:id])
  end
end
