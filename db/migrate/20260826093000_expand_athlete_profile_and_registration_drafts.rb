class ExpandAthleteProfileAndRegistrationDrafts < ActiveRecord::Migration[8.1]
  def change
    change_table :athletes, bulk: true do |t|
      t.string :contact_number
      t.string :blood_group
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.text :address
      t.string :government_id_document_type
    end

    change_table :tournaments, bulk: true do |t|
      t.string :payment_account_name
      t.string :payment_bank_name
      t.string :payment_account_number
      t.string :payment_ifsc
      t.text :payment_instructions
    end
  end
end
