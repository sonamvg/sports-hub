class CreateTournamentReferees < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_referees do |t|
      t.references :tournament, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :role
      t.string :qualification
      t.string :certification_id
      t.string :affiliation
      t.text :notes
      t.timestamps
    end

    add_index :tournament_referees, [:tournament_id, :name]
  end
end
