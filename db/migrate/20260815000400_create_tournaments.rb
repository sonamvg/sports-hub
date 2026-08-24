class CreateTournaments < ActiveRecord::Migration[8.1]
  def change
    create_table :tournaments do |t|
      t.string :name, null: false
      t.string :slug
      t.text :description
      t.string :venue
      t.string :city
      t.string :state
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.datetime :registration_opens_at
      t.datetime :registration_closes_at
      t.integer :status, null: false, default: 0
      t.references :organizer, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :tournaments, :slug, unique: true
  end
end
