class ProfilesController < ApplicationController
  before_action :require_user

  def show; end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    current_password = password_params[:current_password]

    if current_password.blank?
      current_user.errors.add(:current_password, "must be entered")
      return render :show, status: :unprocessable_entity
    end

    unless current_user.authenticate(current_password)
      current_user.errors.add(:current_password, "is incorrect")
      return render :show, status: :unprocessable_entity
    end

    if current_user.update(password: password_params[:password], password_confirmation: password_params[:password_confirmation])
      redirect_to profile_path, notice: "Password updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.super_admin?
      return redirect_to profile_path, alert: "Super admin accounts can't be deleted from here."
    end

    deactivated = delete_account!(current_user)
    reset_session

    notice = deactivated ? "Your account has been deactivated. Your closed tournaments have been preserved." : "Your account has been deleted."
    redirect_to root_path, notice: notice
  end

  private

  # Returns true if the account was deactivated instead of removed outright
  # (only happens when the user organizes at least one tournament that must
  # be preserved — see Tournament::PRESERVED_ON_ACCOUNT_DELETION_STATUSES).
  def delete_account!(user)
    ActiveRecord::Base.transaction do
      user.owned_academies.find_each(&:destroy!) if user.academy_owner?

      user.organized_tournaments
        .where.not(status: Tournament::PRESERVED_ON_ACCOUNT_DELETION_STATUSES)
        .find_each(&:destroy!)

      if user.organized_tournaments.exists?
        user.deactivate!
        true
      else
        user.destroy!
        false
      end
    end
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  # Deliberately excludes :email — the account's sign-in identifier isn't
  # editable from here — and :role, which is set by signup/approval flows,
  # not something a user changes on themselves.
  def profile_params
    params.require(:user).permit(:name, :phone)
  end
end
