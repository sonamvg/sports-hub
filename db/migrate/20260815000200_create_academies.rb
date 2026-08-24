class CreateAcademies < ActiveRecord::Migration[8.1]
  def change
    create_table :academies do |t|
      t.string :name, null: false
      t.string :registration_number
      t.string :city, null: false
      t.string :state
      t.string :country, default: "India"
      t.string :contact_name
      t.string :phone
      t.string :email
      t.timestamps
    end
  end
end
