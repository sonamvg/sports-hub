class AddOrganizerReviewFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :organizer_status, :integer, null: false, default: 0
    add_column :users, :organizer_approved_at, :datetime
    add_column :users, :organizer_rejected_at, :datetime
    add_column :users, :profile_photo_url, :string
    add_reference :users, :organizer_reviewed_by, foreign_key: { to_table: :users }
  end
end
