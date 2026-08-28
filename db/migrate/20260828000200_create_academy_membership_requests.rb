class CreateAcademyMembershipRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :athletes, :external_academy_name, :string

    create_table :academy_membership_requests do |t|
      t.references :academy, null: false, foreign_key: true
      t.references :athlete, null: false, foreign_key: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :academy_membership_requests,
      [:academy_id, :athlete_id, :status],
      unique: true,
      where: "status = 0",
      name: "idx_pending_academy_membership_requests"
  end
end
