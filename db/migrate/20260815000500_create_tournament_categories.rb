class CreateTournamentCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_categories do |t|
      t.references :tournament, null: false, foreign_key: true
      t.string :name, null: false
      t.string :event_type, null: false
      t.string :gender
      t.integer :age_min
      t.integer :age_max
      t.decimal :weight_min, precision: 5, scale: 2
      t.decimal :weight_max, precision: 5, scale: 2
      t.string :belt_min
      t.string :belt_max
      t.timestamps
    end
  end
end
