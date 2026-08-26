class CreateTournamentOrganizers < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_organizers do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.references :added_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tournament_organizers, [:tournament_id, :user_id], unique: true
  end
end
