class AddMiddleNameToAthletes < ActiveRecord::Migration[8.1]
  def change
    add_column :athletes, :middle_name, :string
  end
end
