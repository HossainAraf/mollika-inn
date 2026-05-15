class BookingsController < ApplicationController
  skip_before_action :require_authentication

  def check_availability
    @check_in  = Date.parse(params[:check_in])
    @check_out = Date.parse(params[:check_out])
    @room_types = RoomType.visible.ordered.select { |rt| rt.available_rooms_count(@check_in, @check_out) > 0 }
    render partial: "rooms/availability_results",
           locals: { room_types: @room_types, check_in: @check_in, check_out: @check_out }
  rescue ArgumentError, TypeError
    render plain: "", status: :unprocessable_entity
  end

  def new
    @room_type  = RoomType.find_by!(slug: params[:room_type_slug])
    @check_in   = Date.parse(params[:check_in])
    @check_out  = Date.parse(params[:check_out])
    @nights     = (@check_out - @check_in).to_i
    @price      = @room_type.price_for(@check_in)
    @total      = @price * @nights
    @booking    = Booking.new
    @guest      = Guest.new
  rescue ArgumentError, ActiveRecord::RecordNotFound
    redirect_to rooms_path, alert: "Please select valid dates and a room type."
  end

  def create
    @room_type  = RoomType.find_by!(slug: params[:room_type_slug])
    @check_in   = Date.parse(params[:booking][:check_in_date])
    @check_out  = Date.parse(params[:booking][:check_out_date])
    @nights     = (@check_out - @check_in).to_i
    @price      = @room_type.price_for(@check_in)

    @guest = Guest.find_or_initialize_by(email: booking_params[:guest][:email].downcase)
    @guest.assign_attributes(booking_params[:guest])

    available_room = @room_type.rooms.available.first
    unless available_room
      redirect_to rooms_path, alert: "Sorry, no rooms available for your selected dates."
      return
    end

    @booking = Booking.new(
      guest: @guest,
      check_in_date: @check_in,
      check_out_date: @check_out,
      num_adults: booking_params[:num_adults],
      num_children: booking_params[:num_children] || 0,
      special_requests: booking_params[:special_requests],
      status: "pending",
      payment_status: "unpaid",
      total_amount: @price * @nights
    )

    ActiveRecord::Base.transaction do
      @guest.save!
      @booking.save!
      @booking.booking_rooms.create!(
        room: available_room,
        room_type: @room_type,
        rate_per_night: @price,
        total_amount: @price * @nights
      )
    end

    redirect_to booking_path(@booking), notice: "Booking received! We will confirm shortly."
  rescue ActiveRecord::RecordInvalid
    @total = @price * @nights
    flash.now[:alert] = "Please check the form and try again."
    render :new, status: :unprocessable_entity
  end

  def show
    @booking = Booking.find(params[:id])
  end

  private

  def booking_params
    params.require(:booking).permit(
      :check_in_date, :check_out_date, :num_adults, :num_children, :special_requests,
      guest: [ :first_name, :last_name, :email, :phone, :nationality ]
    )
  end
end
