class AddGroupRegistrationFeeToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :group_registration_fee, :decimal, precision: 10, scale: 2
  end
end
