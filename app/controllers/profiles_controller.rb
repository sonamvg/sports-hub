class ProfilesController < ApplicationController
  before_action :require_user
  before_action :set_athlete_tab_data

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

    notice = deactivated ? "Your account has been deactivated instead of deleted, to preserve tournament and match history you're part of." : "Your account has been deleted."
    redirect_to root_path, notice: notice
  end

  private

  def set_athlete_tab_data
    return unless current_user.athlete?

    @athlete = current_user.athletes.order(:created_at).first
    return unless @athlete

    @available_academies = Academy.approved.order(:name)
    @return_to = profile_path
  end

  # Returns true if the account was deactivated instead of removed outright
  # — because the user organizes at least one tournament that must be
  # preserved (see Tournament::PRESERVED_ON_ACCOUNT_DELETION_STATUSES),
  # because their athlete profile has match history that must be preserved
  # (see Athlete#has_match_history?/#anonymize!), or because they're still
  # referenced by some other operational/audit record (see
  # User#has_operational_references?). A hard delete is only attempted once
  # none of that is true, so it can never hit a foreign key violation.
  #
  # Destroying a non-preserved tournament here is safe even with a
  # generated draw: TournamentCategory declares has_many :matches,
  # dependent: :destroy ahead of has_many :registrations, so Rails clears
  # out its Match rows before it destroys the registrations they reference
  # (Athlete has no such sibling association, which is exactly why it needs
  # the explicit #has_match_history? check instead).
  def delete_account!(user)
    ActiveRecord::Base.transaction do
      user.owned_academies.find_each(&:destroy!) if user.academy_owner?

      user.organized_tournaments
        .where.not(status: Tournament::PRESERVED_ON_ACCOUNT_DELETION_STATUSES)
        .find_each(&:destroy!)

      athlete_preserved = user.athletes.to_a.reduce(false) { |preserved, athlete| !athlete.delete_or_anonymize! || preserved }

      if athlete_preserved || user.organized_tournaments.exists? || user.has_operational_references?
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
