ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module AuthenticationTestHelper
  def sign_in_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end

  def identity_document_upload
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/identity.pdf"), "application/pdf")
  end

  def identity_image_upload
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/tournament-image.png"), "image/png")
  end

  def tournament_image_upload
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/tournament-image.png"), "image/png")
  end

  def payment_receipt_upload
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/payment-receipt.png"), "image/png")
  end

  def invalid_text_upload
    Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/not-an-image.txt"), "text/plain")
  end

  def oversized_upload(filename: "oversized.png", content_type: "image/png")
    Rack::Test::UploadedFile.new(StringIO.new("x" * (5.megabytes + 1)), content_type, original_filename: filename)
  end

  def consent_params
    { terms_accepted: "1", data_sharing_consent: "1" }
  end

  def create_weight_verified_registration(tournament:, category:, email:)
    parent = User.create!(name: "Parent #{email}", email: email, password: "password123", role: :parent)
    athlete = parent.athletes.create!(
      first_name: "Athlete",
      last_name: email.split("@").first,
      date_of_birth: Date.new(1995, 1, 1),
      gender: "male"
    )

    Registration.create!(
      tournament: tournament,
      athlete: athlete,
      tournament_category: category,
      status: :weight_verified,
      payment_receipt: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/payment-receipt.png"), "image/png")
    )
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationTestHelper
  include ActionMailer::TestHelper
end

class ActiveSupport::TestCase
  include AuthenticationTestHelper
  include ActionMailer::TestHelper
end
