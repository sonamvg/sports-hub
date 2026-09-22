class AddMovedFromRegistrationToRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_reference :registrations, :moved_from_registration, null: true, foreign_key: { to_table: :registrations, on_delete: :nullify }
  end
end
