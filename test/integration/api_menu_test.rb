require "test_helper"

class ApiMenuTest < ActionDispatch::IntegrationTest
  test "menu is public and lists categories" do
    get "/api/menu"
    assert_response :success
    assert_kind_of Array, response.parsed_body["categories"]
  end
end