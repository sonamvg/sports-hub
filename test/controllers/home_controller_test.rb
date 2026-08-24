require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "homepage shows previous competitions" do
    get root_path

    assert_response :success
    assert_includes response.body, "PREVIOUS COMPETITIONS"
    assert_includes response.body, "2025 U.S. Open Taekwondo Championship"
    assert_includes response.body, "Wuxi 2025 World Taekwondo Championships"
    assert_includes response.body, "https://www.usatkd.org/2025-u-s-open-taekwondo-championship"
  end
end
