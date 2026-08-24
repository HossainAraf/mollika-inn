class HomeController < ApplicationController
  skip_before_action :require_authentication

  def index
    @room_types = RoomType.visible.includes(photos_attachments: :blob).ordered
    @facilities = Facility.visible.ordered.limit(8)
    @dining_facilities = Facility.visible.where(category: "dining").ordered
    @reviews = Review.approved.includes(:guest).recent.limit(4)
    @check_in  = params[:check_in]  || Date.today.to_s
    @check_out = params[:check_out] || (Date.today + 1).to_s
  end

  def about
  end

  def conference
    @facility = Facility.find_by(name: "conference") || Facility.new(name: "Conference & Event Venue")
  end
end
