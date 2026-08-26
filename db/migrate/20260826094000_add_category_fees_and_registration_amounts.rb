class AddCategoryFeesAndRegistrationAmounts < ActiveRecord::Migration[8.1]
  def change
    add_column :tournament_categories, :registration_fee, :decimal, precision: 10, scale: 2
    add_column :registrations, :fee_amount, :decimal, precision: 10, scale: 2
    add_column :registrations, :fee_currency, :string
  end
end
