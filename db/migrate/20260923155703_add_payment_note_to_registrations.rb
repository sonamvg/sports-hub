class AddPaymentNoteToRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_column :registrations, :payment_note, :string
  end
end
