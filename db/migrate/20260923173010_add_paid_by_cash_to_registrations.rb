class AddPaidByCashToRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_column :registrations, :paid_by_cash, :boolean, default: false, null: false
  end
end
