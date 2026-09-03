module SuperAdmin
  class AthletesController < ApplicationController
    before_action :require_user
    before_action :require_super_admin
    before_action :set_athlete, only: :destroy

    def index
      @athletes = Athlete.includes(:academy, :user).order(:first_name, :last_name, :id)
      @athletes, @pagination = paginate(@athletes, per_page: 20)
    end

    def destroy
      @athlete.destroy
      redirect_to super_admin_athletes_path, notice: "Athlete profile removed."
    end

    private

    def set_athlete
      @athlete = Athlete.find(params[:id])
    end
  end
end
