class RoomsController < ApplicationController
  skip_before_action :require_authentication

  def index
    @room_types = RoomType.visible.includes(photos_attachments: :blob).ordered
    @check_in  = params[:check_in]
    @check_out = params[:check_out]

    if @check_in.present? && @check_out.present?
      check_in_date  = Date.parse(@check_in)
      check_out_date = Date.parse(@check_out)
      @room_types = @room_types.select { |rt| rt.available_rooms_count(check_in_date, check_out_date) > 0 }
    end
  end

  def show
    @room_type = RoomType.find_by!(slug: params[:slug])
    @check_in  = params[:check_in]  || Date.today.to_s
    @check_out = params[:check_out] || (Date.today + 1).to_s
    @reviews   = Review.approved.joins(:booking).joins("JOIN booking_rooms ON booking_rooms.booking_id = bookings.id")
                       .where(booking_rooms: { room_type_id: @room_type.id }).recent.limit(5)
  end
end
