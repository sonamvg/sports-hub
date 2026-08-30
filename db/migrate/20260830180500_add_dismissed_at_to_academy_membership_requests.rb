class AddDismissedAtToAcademyMembershipRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_membership_requests, :dismissed_at, :datetime
    add_index :academy_membership_requests, :dismissed_at
  end
end
