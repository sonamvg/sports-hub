class TournamentOrganizer < ApplicationRecord
  belongs_to :tournament
  belongs_to :user
  belongs_to :added_by, class_name: "User", optional: true

  enum :role, { collaborator: 0, super_organizer: 1 }, default: :collaborator

  validates :user_id, uniqueness: { scope: :tournament_id }
end
