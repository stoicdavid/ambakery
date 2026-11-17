require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "navidad wraps past new year" do
    navidad = Category.new(name: "Navidad", seasonal: true, starts_on: Date.new(2026, 12, 1), ends_on: Date.new(2027, 1, 6))
    assert navidad.in_season?(Date.new(2027, 12, 24))
    assert navidad.in_season?(Date.new(2028, 1, 5))
    assert_not navidad.in_season?(Date.new(2027, 2, 1))
  end
end