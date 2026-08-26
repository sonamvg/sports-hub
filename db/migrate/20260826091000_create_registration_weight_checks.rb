class CreateRegistrationWeightChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_weight_checks do |t|
      t.references :registration, null: false, foreign_key: true
      t.references :checked_by, null: false, foreign_key: { to_table: :users }
      t.integer :attempt_number, null: false
      t.decimal :weight, precision: 5, scale: 2, null: false
      t.boolean :passed, null: false, default: false
      t.datetime :checked_at, null: false

      t.timestamps
    end

    add_index :registration_weight_checks, [:registration_id, :attempt_number], unique: true
    add_check_constraint :registration_weight_checks, "attempt_number BETWEEN 1 AND 3", name: "registration_weight_checks_attempt_number_range"
    add_check_constraint :registration_weight_checks, "weight > 0", name: "registration_weight_checks_weight_positive"
  end
end
