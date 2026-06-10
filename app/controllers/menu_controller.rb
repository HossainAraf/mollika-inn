class MenuController < ApplicationController
  skip_before_action :require_authentication

  def index
    @menu_items = MenuItem.available.by_category
  end
end
