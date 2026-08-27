class AddCourtsCountToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :courts_count, :integer
  end
end
