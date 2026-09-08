class RemoveSlugFromTournaments < ActiveRecord::Migration[8.1]
  def change
    remove_column :tournaments, :slug, :string
  end
end
