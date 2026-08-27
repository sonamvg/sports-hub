class CreateTournamentOrganizerInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_organizer_invitations do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.integer :status, null: false, default: 0
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :tournament_organizer_invitations, [:tournament_id, :email], unique: true
  end
end
