class AddCountryToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :country, :string, default: "India"
  end
end
