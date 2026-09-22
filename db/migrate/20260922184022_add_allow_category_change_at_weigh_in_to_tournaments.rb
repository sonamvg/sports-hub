class AddAllowCategoryChangeAtWeighInToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :allow_category_change_at_weigh_in, :boolean, default: false, null: false
  end
end
