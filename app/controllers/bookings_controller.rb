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
    # Validate room_type_slug
    @room_type = RoomType.find_by(slug: params[:room_type_slug])
    unless @room_type
      redirect_to rooms_path, alert: "Invalid room type selected. Please choose a room type."
      return
    end

    # Validate and parse check-in/check-out dates
    unless params[:check_in].present? && params[:check_out].present?
      redirect_to room_path(@room_type.slug), alert: "Please select check-in and check-out dates."
      return
    end

    begin
      @check_in   = Date.parse(params[:check_in])
      @check_out  = Date.parse(params[:check_out])
    rescue ArgumentError
      redirect_to room_path(@room_type.slug), alert: "Invalid date format. Please use a valid date."
      return
    end

    # Validate date logic
    if @check_in < Date.today
      redirect_to room_path(@room_type.slug), alert: "Check-in date cannot be in the past."
      return
    end

    if @check_out <= @check_in
      redirect_to room_path(@room_type.slug), alert: "Check-out date must be after check-in date."
      return
    end

    @nights     = (@check_out - @check_in).to_i
    @price      = @room_type.price_for(@check_in)
    @total      = @price * @nights
    @booking    = Booking.new
    @guest      = Guest.new
  end

  def create
    # Validate room type
    @room_type = RoomType.find_by(slug: params[:room_type_slug])
    unless @room_type
      redirect_to rooms_path, alert: "Invalid room type selected."
      return
    end

    begin
      @check_in   = Date.parse(params[:booking][:check_in_date])
      @check_out  = Date.parse(params[:booking][:check_out_date])
    rescue ArgumentError
      redirect_to room_path(@room_type.slug), alert: "Invalid date format."
      return
    end

    # Validate date logic
    if @check_in < Date.today
      redirect_to room_path(@room_type.slug), alert: "Check-in date cannot be in the past."
      return
    end

    if @check_out <= @check_in
      redirect_to room_path(@room_type.slug), alert: "Check-out date must be after check-in date."
      return
    end

    @nights     = (@check_out - @check_in).to_i
    @price      = @room_type.price_for(@check_in)

    # Use Guest.find_by_or_create_by_email to prefer an existing guest by email
    # and initialize a new guest when none exists. This avoids uniqueness
    # validation failures for emails that are already registered.
    @guest = Guest.find_by_or_create_by_email(booking_params[:guest])

     # Validate the guest for all records, including new and existing guests.
     unless @guest.valid?
        @booking = Booking.new(
          check_in_date: @check_in,
          check_out_date: @check_out,
          num_adults: booking_params[:num_adults],
          num_children: booking_params[:num_children] || 0,
          special_requests: booking_params[:special_requests]
        )
        @total = @price * @nights
        flash.now[:alert] = "Please check the guest details and try again."
        render :new, status: :unprocessable_entity
        return
     end

    available_room = @room_type.rooms.ordered.find { |room| room.available_between?(@check_in, @check_out) }
    unless available_room
      redirect_to room_path(@room_type.slug), alert: "Sorry, no rooms available for your selected dates."
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
    ).tap do |booking|
      booking.guest_name = submitted_guest_name if booking.respond_to?(:guest_name=)
    end

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

  def submitted_guest_name
    booking_params[:guest].values_at(:first_name, :last_name).compact.join(" ").squish
  end
end
