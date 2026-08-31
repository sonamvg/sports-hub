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
end

class ActionDispatch::IntegrationTest
  include AuthenticationTestHelper
  include ActionMailer::TestHelper
end

class ActiveSupport::TestCase
  include AuthenticationTestHelper
  include ActionMailer::TestHelper
end
