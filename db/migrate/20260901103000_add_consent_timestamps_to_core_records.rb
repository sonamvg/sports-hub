class AddConsentTimestampsToCoreRecords < ActiveRecord::Migration[8.1]
  def change
    change_table :athletes, bulk: true do |t|
      t.datetime :terms_accepted_at
      t.datetime :data_sharing_consent_accepted_at
    end

    change_table :academies, bulk: true do |t|
      t.datetime :terms_accepted_at
      t.datetime :data_sharing_consent_accepted_at
    end

    change_table :tournaments, bulk: true do |t|
      t.datetime :terms_accepted_at
      t.datetime :data_sharing_consent_accepted_at
    end
  end
end
