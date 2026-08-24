module Organizer
  class RegistrationsController < ApplicationController
    before_action :require_user
    before_action :set_registration, only: %i[show approve reject]

    def index
      @registrations = visible_registrations.includes(:athlete, :tournament, :tournament_category).order(created_at: :desc)
    end

    def show; end

    def approve
      @registration.update!(status: :approved, verified_at: Time.current)
      redirect_to organizer_registrations_path, notice: "Registration approved."
    end

    def reject
      @registration.update!(status: :rejected, verified_at: Time.current)
      redirect_to organizer_registrations_path, notice: "Registration rejected."
    end

    private

    def visible_registrations
      return Registration.all if super_admin?

      Registration.joins(:tournament).where(tournaments: { organizer_id: current_user.id })
    end

    def set_registration
      @registration = visible_registrations.find(params[:id])
    end
  end
end
