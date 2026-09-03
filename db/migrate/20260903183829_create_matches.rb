class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :tournament_category, null: false, foreign_key: true
      t.integer :round_number, null: false
      t.integer :slot_position, null: false
      t.bigint :registration_one_id
      t.bigint :registration_two_id
      t.bigint :winner_registration_id
      t.integer :status, null: false, default: 0
      t.integer :medal, null: false, default: 0
      t.integer :decision
      t.jsonb :score_data, null: false, default: {}
      t.bigint :next_match_id
      t.integer :next_match_slot
      t.datetime :completed_at

      t.timestamps
    end

    add_foreign_key :matches, :registrations, column: :registration_one_id
    add_foreign_key :matches, :registrations, column: :registration_two_id
    add_foreign_key :matches, :registrations, column: :winner_registration_id
    add_foreign_key :matches, :matches, column: :next_match_id

    add_index :matches, :registration_one_id
    add_index :matches, :registration_two_id
    add_index :matches, :winner_registration_id
    add_index :matches, :next_match_id
    add_index :matches, [ :tournament_category_id, :round_number, :slot_position ], unique: true, name: "index_matches_on_category_round_slot"
  end
end
