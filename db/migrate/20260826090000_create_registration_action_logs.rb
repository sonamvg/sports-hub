class CreateRegistrationActionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :registration_action_logs do |t|
      t.references :registration, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :from_status
      t.string :to_status, null: false

      t.timestamps
    end
  end
end
