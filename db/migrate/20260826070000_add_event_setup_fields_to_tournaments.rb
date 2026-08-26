class AddEventSetupFieldsToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :tournament_level, :string
    add_column :tournaments, :organizing_organization, :string
    add_column :tournaments, :time_zone, :string
    add_column :tournaments, :primary_contact_name, :string
    add_column :tournaments, :primary_contact_email, :string
    add_column :tournaments, :primary_contact_phone, :string
    add_column :tournaments, :competition_formats, :text
    add_column :tournaments, :eligibility_summary, :text
    add_column :tournaments, :category_generation_method, :string
    add_column :tournaments, :registration_capacity, :integer
    add_column :tournaments, :registration_fee, :decimal, precision: 10, scale: 2
    add_column :tournaments, :currency, :string
    add_column :tournaments, :required_documents, :text
    add_column :tournaments, :refund_policy, :text
    add_column :tournaments, :banner_image_url, :string
  end
end
