class CreateAthletes < ActiveRecord::Migration[8.1]
  def change
    create_table :athletes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :academy, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth, null: false
      t.string :gender, null: false
      t.string :belt
      t.decimal :weight, precision: 5, scale: 2
      t.string :association_id
      t.string :city
      t.string :state
      t.string :country, default: "India"
      t.timestamps
    end
  end
end
