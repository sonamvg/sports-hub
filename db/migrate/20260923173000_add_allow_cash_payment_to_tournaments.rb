class AddAllowCashPaymentToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :allow_cash_payment, :boolean, default: false, null: false
  end
end
