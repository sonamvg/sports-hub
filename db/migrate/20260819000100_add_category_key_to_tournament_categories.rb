class AddCategoryKeyToTournamentCategories < ActiveRecord::Migration[8.1]
  def up
    add_column :tournament_categories, :category_key, :string

    execute <<~SQL.squish
      UPDATE tournament_categories
      SET category_key = lower(concat_ws('|',
        coalesce(event_type, ''),
        coalesce(gender, ''),
        coalesce(age_min::text, ''),
        coalesce(age_max::text, ''),
        coalesce(trim(trailing '.' from trim(trailing '0' from weight_min::text)), ''),
        coalesce(trim(trailing '.' from trim(trailing '0' from weight_max::text)), ''),
        coalesce(belt_min, ''),
        coalesce(belt_max, '')
      ))
    SQL

    change_column_null :tournament_categories, :category_key, false
    add_index :tournament_categories, [:tournament_id, :category_key], unique: true, name: "index_categories_unique_identity"
  end

  def down
    remove_index :tournament_categories, name: "index_categories_unique_identity"
    remove_column :tournament_categories, :category_key
  end
end
