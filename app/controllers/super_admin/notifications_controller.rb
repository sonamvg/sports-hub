module SuperAdmin
  class NotificationsController < ApplicationController
    before_action :require_user
    before_action :require_super_admin
    before_action :set_notification, only: %i[approve reject dismiss]

    def index
      @notifications = SuperAdminNotification.active.includes(:actor, :notifiable).latest_first
      @notifications, @pagination = paginate(@notifications)
    end

    def approve
      @notification.approve!(reviewer: current_user)
      redirect_to super_admin_notifications_path, notice: "Notification approved."
    end

    def reject
      @notification.reject!(reviewer: current_user)
      redirect_to super_admin_notifications_path, notice: "Notification rejected."
    end

    def dismiss
      @notification.dismiss!
      redirect_to super_admin_notifications_path, notice: "Notification dismissed."
    end

    private

    def set_notification
      @notification = SuperAdminNotification.active.find(params[:id])
    end
  end
end
