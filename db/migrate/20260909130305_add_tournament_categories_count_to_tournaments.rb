class AddTournamentCategoriesCountToTournaments < ActiveRecord::Migration[8.1]
  def up
    add_column :tournaments, :tournament_categories_count, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE tournaments
      SET tournament_categories_count = (
        SELECT COUNT(*) FROM tournament_categories WHERE tournament_categories.tournament_id = tournaments.id
      )
    SQL
  end

  def down
    remove_column :tournaments, :tournament_categories_count
  end
end
