class AddProfilePhotoUrlToAthletes < ActiveRecord::Migration[8.1]
  def change
    add_column :athletes, :profile_photo_url, :string
  end
end
