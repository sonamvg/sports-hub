require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "homepage shows black belt hero photo" do
    get root_path

    assert_response :success
    assert_includes response.body, "black-belt-dobok"
    assert_includes response.body, "Close-up of a black belt tied over a white taekwondo uniform"
    assert_includes response.body, "READY FOR THE MAT"
  end

  test "homepage shows previous competitions" do
    get root_path

    assert_response :success
    assert_includes response.body, "PREVIOUS COMPETITIONS"
    assert_includes response.body, "2025 U.S. Open Taekwondo Championship"
    assert_includes response.body, "Wuxi 2025 World Taekwondo Championships"
    assert_includes response.body, "https://www.usatkd.org/2025-u-s-open-taekwondo-championship"
  end

  test "homepage shows sports news instead of journey section" do
    get root_path

    assert_response :success
    assert_includes response.body, "SPORTS NEWS"
    assert_includes response.body, "Domestic"
    assert_includes response.body, "International"
    assert_includes response.body, "Khelo India and federation support expanded"
    assert_includes response.body, "World Taekwondo Grand Prix calendar continues"
    assert_not_includes response.body, "THE JOURNEY"
  end

  test "homepage shows taekwondo blogs and youtube links" do
    get root_path

    assert_response :success
    assert_includes response.body, "TAEKWONDO BLOGS"
    assert_includes response.body, "Traditional Taekwondo Ramblings"
    assert_includes response.body, "SportsEdTV Taekwondo"
    assert_includes response.body, "YOUTUBE PICKS"
    assert_includes response.body, "Open YouTube"
    assert_includes response.body, "https://www.youtube.com/results?search_query=413+R32+Men+80kg+USA+NICKOLAS+C+A+ROU+CRISTESCU+M+A"
  end
end
