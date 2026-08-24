class AddOwnershipAndStatusToAcademies < ActiveRecord::Migration[8.1]
  def change
    add_reference :academies, :owner, foreign_key: { to_table: :users }
    add_column :academies, :status, :integer, null: false, default: 0
    add_column :academies, :reviewed_at, :datetime
    add_column :academies, :rejection_reason, :text
  end
end
