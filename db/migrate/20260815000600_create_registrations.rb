class CreateRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :registrations do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :athlete, null: false, foreign_key: true
      t.references :tournament_category, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.decimal :registered_weight, precision: 5, scale: 2
      t.string :registration_number
      t.datetime :verified_at
      t.timestamps
    end
    add_index :registrations, [:tournament_id, :athlete_id, :tournament_category_id], unique: true, name: "index_registrations_unique_entry"
  end
end
