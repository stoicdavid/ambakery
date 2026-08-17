require "test_helper"

class ProductTest < ActiveSupport::TestCase
  fixtures :products
  test "product attributes must not be empty" do
    product = Product.new
    assert product.invalid?
    assert product.errors[:name].any?
    assert product.errors[:description].any?
    assert product.errors[:slug].any?
    assert product.errors[:price].any?
    assert product.errors[:image].any?
  end

  test "product price must be a positive number" do
    product = Product.new(name: "Mi Pan",
      description: "Un pan delicioso")
    product.image.attach(io:
      File.open("test/fixtures/files/pastelito.png"),
      filename: "pastelito.png", content_type: "image/png")
    product.price = -10.0
    assert product.invalid?
    assert_equal ["must be greater than or equal to 0.01"], product.errors[:price]

    product.price = 0.0
    assert product.invalid?
    assert_equal ["must be greater than or equal to 0.01"], product.errors[:price]

    product.price = 1
    assert product.valid?
  end

  test "product is not valid without a unique name" do
    product = Product.new(name: products(:panecito).name,
      description: "yyy",
      price: 1)
    product.image.attach(io: File.open("test/fixtures/files/panecito.png"),
      filename: "panecito.png", content_type: "image/png")
    assert product.invalid?
    assert_equal [ "has already been taken" ], product.errors[:name]
  end
end
