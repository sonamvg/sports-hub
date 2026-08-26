class AddOrganizerProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :organizer_designation, :string
    add_reference :users, :organizer_academy, foreign_key: { to_table: :academies }
  end
end
