class AddPaymentUpiIdToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :payment_upi_id, :string
  end
end
