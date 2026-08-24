ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module AuthenticationTestHelper
  def sign_in_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationTestHelper
end
