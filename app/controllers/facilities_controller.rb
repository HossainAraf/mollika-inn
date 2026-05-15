class FacilitiesController < ApplicationController
  skip_before_action :require_authentication

  def index
    @facilities = Facility.visible.by_category
    @facilities_by_category = @facilities.group_by(&:category)
  end
end
