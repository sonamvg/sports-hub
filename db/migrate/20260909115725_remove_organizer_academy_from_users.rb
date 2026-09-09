class RemoveOrganizerAcademyFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_reference :users, :organizer_academy, foreign_key: { to_table: :academies }
  end
end
