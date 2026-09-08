module SuperAdmin
  class AthletesController < ApplicationController
    before_action :require_user
    before_action :require_super_admin
    before_action :set_athlete, only: :destroy

    def index
      @query = params[:q].to_s.squish
      @athletes = filtered_athletes.order(:first_name, :last_name, :id)
      @total_count = @athletes.count
      @athletes, @pagination = paginate(@athletes, per_page: 20)
    end

    def destroy
      @athlete.destroy
      redirect_to super_admin_athletes_path, notice: "Athlete profile removed."
    end

    private

    def filtered_athletes
      athletes = Athlete.includes(:academy, :user).left_joins(:academy).joins(:user)
      return athletes if @query.blank?

      like_query = "%#{@query.downcase}%"
      athletes.where(
        "LOWER(athletes.first_name) LIKE :q OR LOWER(athletes.last_name) LIKE :q OR
         LOWER(CONCAT(athletes.first_name, ' ', athletes.last_name)) LIKE :q OR
         LOWER(COALESCE(athletes.association_id, '')) LIKE :q OR
         LOWER(COALESCE(academies.name, '')) LIKE :q OR
         LOWER(users.email) LIKE :q",
        q: like_query
      )
    end

    def set_athlete
      @athlete = Athlete.find(params[:id])
    end
  end
end
