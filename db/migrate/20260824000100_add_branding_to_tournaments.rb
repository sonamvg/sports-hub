class AddBrandingToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :website_url, :string
    add_column :tournaments, :logo_url, :string
  end
end
