class Admin::BookingsController < Admin::BaseController
  before_action :set_booking, only: [ :show, :edit, :update, :destroy, :confirm, :check_in, :check_out, :cancel ]

  def index
    @bookings = Booking.includes(:guest, :room_types).order(created_at: :desc)
    @bookings = @bookings.where(status: params[:status]) if params[:status].present?
    @bookings = @bookings.where(payment_status: params[:payment_status]) if params[:payment_status].present?

    if params[:q].present?
      query = "%#{params[:q].strip.downcase}%"
      @bookings = @bookings.joins(:guest).where(
        "LOWER(bookings.guest_name) LIKE ? OR LOWER(guests.first_name) LIKE ? OR LOWER(guests.last_name) LIKE ? OR LOWER(guests.email) LIKE ? OR bookings.id::text = ?",
        query, query, query, query, params[:q].strip
      ).distinct
    end

    @bookings = @bookings.where("check_in_date >= ?", Date.parse(params[:from])) if params[:from].present?
    @bookings = @bookings.where("check_out_date <= ?", Date.parse(params[:to])) if params[:to].present?
    @page = (params[:page].to_i.positive? ? params[:page].to_i : 1)
    @bookings = @bookings.offset((@page - 1) * 20).limit(20)
  end

  def new
    @booking = Booking.new
    @guest = Guest.new
    @room_types = RoomType.includes(:rooms).ordered
  end

  def create
    @room_types = RoomType.includes(:rooms).ordered
    @booking = Booking.new
    @guest = Guest.new

    begin
      @check_in = Date.parse(params[:booking][:check_in_date])
      @check_out = Date.parse(params[:booking][:check_out_date])
    rescue ArgumentError, TypeError
      @booking.errors.add(:base, "Please enter valid check-in and check-out dates.")
      flash.now[:alert] = "Please enter valid check-in and check-out dates."
      render :new, status: :unprocessable_entity
      return
    end

    if @check_out <= @check_in
      @booking.errors.add(:base, "Check-out date must be after check-in date.")
      flash.now[:alert] = "Check-out date must be after check-in date."
      render :new, status: :unprocessable_entity
      return
    end

    @room_type = RoomType.find_by(id: params[:booking][:room_type_id])
    unless @room_type
      @booking.errors.add(:base, "Please select a room type.")
      flash.now[:alert] = "Please select a room type."
      render :new, status: :unprocessable_entity
      return
    end

    @guest = Guest.new(booking_params[:guest])
    existing_guest = Guest.find_by(email: @guest.email)
    if existing_guest.present? && @guest.email.present?
      @guest = existing_guest
    end

    if @guest.invalid?
      flash.now[:alert] = "Please fix the guest details and try again."
      render :new, status: :unprocessable_entity
      return
    end

    @room = @room_type.rooms.available.first
    unless @room
      flash.now[:alert] = "No available rooms found for this room type on the selected dates."
      render :new, status: :unprocessable_entity
      return
    end

    @booking = Booking.new(
      guest: @guest,
      check_in_date: @check_in,
      check_out_date: @check_out,
      num_adults: booking_params[:num_adults].to_i,
      num_children: booking_params[:num_children].to_i,
      special_requests: booking_params[:special_requests],
      status: "pending",
      payment_status: booking_params[:payment_status].presence || "unpaid",
      total_amount: booking_params[:total_amount].presence || @room_type.base_price_per_night * (@check_out - @check_in).to_i,
      guest_name: @guest.full_name
    )

    ActiveRecord::Base.transaction do
      @guest.save! if @guest.new_record?
      @booking.save!
      @booking.booking_rooms.create!(
        room: @room,
        room_type: @room_type,
        rate_per_night: @room_type.price_for(@check_in),
        total_amount: @booking.total_amount
      )
    end

    redirect_to admin_booking_path(@booking), notice: "Manual booking created successfully."
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Please check the booking details and try again."
    render :new, status: :unprocessable_entity
  end

  def show; end

  def edit; end

  def update
    if @booking.update(booking_update_params)
      redirect_to admin_booking_path(@booking), notice: "Booking updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @booking.destroy
    redirect_to admin_bookings_path, notice: "Booking deleted."
  end

  def confirm
    @booking.confirm!
    redirect_to admin_booking_path(@booking), notice: "Booking confirmed."
  end

  def check_in
    @booking.check_in!
    redirect_to admin_booking_path(@booking), notice: "Guest checked in."
  end

  def check_out
    @booking.check_out!
    redirect_to admin_booking_path(@booking), notice: "Guest checked out."
  end

  def cancel
    @booking.cancel!(reason: params[:reason])
    redirect_to admin_booking_path(@booking), notice: "Booking cancelled."
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_update_params
    params.require(:booking).permit(:check_in_date, :check_out_date, :special_requests, :payment_status, :paid_amount, :payment_method, :total_amount)
  end

  def booking_params
    params.require(:booking).permit(
      :check_in_date,
      :check_out_date,
      :room_type_id,
      :num_adults,
      :num_children,
      :special_requests,
      :payment_status,
      :total_amount,
      guest: [ :first_name, :last_name, :email, :phone, :nationality ]
    )
  end
end
