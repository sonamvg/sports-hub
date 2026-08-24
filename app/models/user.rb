class User < ApplicationRecord
  has_secure_password
  has_many :athletes, dependent: :destroy
  has_many :owned_academies, class_name: "Academy", foreign_key: :owner_id, dependent: :nullify
  has_many :organized_tournaments, class_name: "Tournament", foreign_key: :organizer_id, dependent: :restrict_with_error

  enum :role, { parent: 0, athlete: 1, coach: 2, organizer: 3, super_admin: 4, academy_owner: 5 }, default: :parent

  before_validation :normalize_email

  validates :name, :email, presence: true
  validates :email, uniqueness: true

  def admin?
    super_admin?
  end

  def can_organize_tournaments?
    organizer? || academy_owner? || super_admin?
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.squish.presence
  end
end
