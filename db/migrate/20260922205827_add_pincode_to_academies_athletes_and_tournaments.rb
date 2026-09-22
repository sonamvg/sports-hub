class AddPincodeToAcademiesAthletesAndTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :academies, :pincode, :string
    add_column :athletes, :pincode, :string
    add_column :tournaments, :pincode, :string
  end
end
