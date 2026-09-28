require "test_helper"

class Admin::MenuItemsControllerTest < ActionDispatch::IntegrationTest
  include AdminAuthTestHelper

  setup do
    login_as_admin
  end

  test "should get index" do
    get admin_menu_items_path

    assert_response :success
  end

  test "should get new" do
    get new_admin_menu_item_path

    assert_response :success
  end

  test "should get edit" do
    menu_item = MenuItem.create!(
      name: "Chicken Curry",
      price: 500,
      category: "bengali"
    )

    get edit_admin_menu_item_path(menu_item)

    assert_response :success
  end

  test "should get show" do
    menu_item = MenuItem.create!(
      name: "Chicken Curry",
      price: 500,
      category: "bengali"
    )

    get admin_menu_item_path(menu_item)

    assert_response :success
  end
end
