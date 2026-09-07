class Admin::BookingsController < Admin::BaseController
  before_action :set_booking, only: [ :show, :edit, :update, :destroy, :confirm, :check_in, :check_out, :cancel ]
  before_action :set_room_types, only: [ :new, :create, :edit, :update ]

  def index
    @bookings = Booking.includes(:guest, :room_types).order(created_at: :desc)
    @bookings = @bookings.where(status: params[:status]) if params[:status].present?
    @bookings = @bookings.where(payment_status: params[:payment_status]) if params[:payment_status].present?

    if params[:q].present?
      query = "%#{params[:q].strip.downcase}%"

      @bookings = @bookings.joins(:guest).where(
        "LOWER(bookings.guest_name) LIKE ? OR
         LOWER(guests.first_name) LIKE ? OR
         LOWER(guests.last_name) LIKE ? OR
         LOWER(guests.email) LIKE ? OR
         bookings.id::text = ?",
        query,
        query,
        query,
        query,
        params[:q].strip
      ).distinct
    end

    @bookings = @bookings.where(
      "check_in_date >= ?",
      Date.parse(params[:from])
    ) if params[:from].present?

    @bookings = @bookings.where(
      "check_out_date <= ?",
      Date.parse(params[:to])
    ) if params[:to].present?

    @page = params[:page].to_i.positive? ? params[:page].to_i : 1

    @bookings = @bookings
      .offset((@page - 1) * 20)
      .limit(20)
  end

  # GET /admin/bookings/new
  #
  # This action also handles the "Update price" button.
  # No JavaScript is required.
  def new
    @room_types = RoomType.includes(:rooms).ordered

    @booking = Booking.new
    @guest = Guest.new

    # Normal first visit
    unless params[:booking].present?
      @selected_check_in = Date.today
      @selected_check_out = Date.tomorrow
      return
    end

    # Preserve submitted form values
    input = booking_form_params

    @selected_room_type_id = input[:room_type_id].presence
    @selected_check_in = input[:check_in_date].presence
    @selected_check_out = input[:check_out_date].presence

    @booking.assign_attributes(
      num_adults: input[:num_adults].presence || 1,
      num_children: input[:num_children].presence || 0,
      payment_status: input[:payment_status].presence || "unpaid",
      special_requests: input[:special_requests]
    )

    @guest = Guest.new(input[:guest] || {})

    # Defaults for dates if one/both are missing
    @selected_check_in ||= Date.today.to_s
    @selected_check_out ||= Date.tomorrow.to_s

    # Only calculate when the admin explicitly clicks "Update price"
    return unless params[:calculate_price].present?

    calculate_booking_price
  end

  # POST /admin/bookings
  def create
    @room_types = RoomType.includes(:rooms).ordered

    input = booking_params.to_h.deep_symbolize_keys

    # If admin supplied a specific room number, use it to determine the room type.
    if input[:room_number].present?
      room = Room.find_by(room_number: input[:room_number])
      if room
        @room_type = room.room_type
        @selected_room_type_id = @room_type.id
        input[:room_type_id] = @room_type.id
      end
    end

    @selected_room_type_id = input[:room_type_id].presence
    @selected_check_in = input[:check_in_date].presence
    @selected_check_out = input[:check_out_date].presence

    begin
      @check_in = Date.parse(input[:check_in_date].to_s)
      @check_out = Date.parse(input[:check_out_date].to_s)
    rescue ArgumentError, TypeError
      prepare_create_form
      @booking.errors.add(
        :base,
        "Please enter valid check-in and check-out dates."
      )

      flash.now[:alert] = "Please enter valid check-in and check-out dates."
      render :new, status: :unprocessable_entity
      return
    end

    if @check_in < Date.today
      prepare_create_form
      @booking.errors.add(
        :check_in_date,
        "cannot be in the past."
      )

      flash.now[:alert] = "Check-in date cannot be in the past."
      render :new, status: :unprocessable_entity
      return
    end

    if @check_out <= @check_in
      prepare_create_form
      @booking.errors.add(
        :check_out_date,
        "must be after check-in date."
      )

      flash.now[:alert] = "Check-out date must be after check-in date."
      render :new, status: :unprocessable_entity
      return
    end

    @room_type = RoomType.find_by(id: input[:room_type_id])

    unless @room_type
      prepare_create_form
      @booking.errors.add(
        :base,
        "Please select a room type."
      )

      flash.now[:alert] = "Please select a room type."
      render :new, status: :unprocessable_entity
      return
    end

    @nights = (@check_out - @check_in).to_i
    @price = @room_type.price_for(@check_in)
    @total = @price * @nights

    # Prefer an existing guest by email, otherwise initialize with submitted attrs.
    @guest = Guest.find_by_or_create_by_email(input[:guest] || {})

    # Validate only when this is a new, unsaved guest.
    if @guest.new_record?
      if @guest.invalid?
        prepare_create_form

        flash.now[:alert] = "Please fix the guest details and try again."
        render :new, status: :unprocessable_entity
        return
      end
    end

    # Use the room type's currently available room.
    #
    # NOTE:
    # This currently follows your existing logic:
    # @room_type.rooms.available.first
    #
    # Date-overlap availability can be improved separately.
    @room = @room_type.rooms.available.first

    unless @room
      prepare_create_form

      flash.now[:alert] =
        "No available rooms found for this room type on the selected dates."

      render :new, status: :unprocessable_entity
      return
    end

    submitted_name = [
      input.dig(:guest, :first_name),
      input.dig(:guest, :last_name)
    ].compact.join(" ").squish

    @booking = Booking.new(
      guest: @guest,
      check_in_date: @check_in,
      check_out_date: @check_out,
      num_adults: input[:num_adults].to_i,
      num_children: input[:num_children].to_i,
      special_requests: input[:special_requests],
      status: "pending",
      payment_status: input[:payment_status].presence || "unpaid",

      # IMPORTANT:
      # Do not trust total_amount submitted by the browser.
      # Always calculate it on the server.
      total_amount: @total,

      guest_name: submitted_name.presence || @guest.full_name
    )

    ActiveRecord::Base.transaction do
      @guest.save! if @guest.new_record?

      @booking.save!

      @booking.booking_rooms.create!(
        room: @room,
        room_type: @room_type,
        rate_per_night: @price,
        total_amount: @total
      )
    end

    redirect_to admin_booking_path(@booking),
      notice: "Manual booking created successfully."

  rescue ActiveRecord::RecordInvalid
    @room_types ||= RoomType.includes(:rooms).ordered

    flash.now[:alert] =
      "Please check the booking details and try again."

    render :new, status: :unprocessable_entity
  end

  def show
  end

  def edit
  end

  def update
    # Prepare attributes for update. `room_number` and `room_type_id` are
    # administrative form inputs but are stored on the booking's first
    # `booking_room` row rather than on `bookings` itself. Extract them and
    # apply them to `booking_rooms` after updating the booking record.
    attrs = booking_update_params.to_h.symbolize_keys

    selected_room_number = attrs.delete(:room_number)
    selected_room_type_id = attrs.delete(:room_type_id)

    room = Room.find_by(room_number: selected_room_number) if selected_room_number.present?

    if @booking.update(attrs)
      # Persist room / room_type changes to the first booking_room record
      booking_room = @booking.booking_rooms.first
      if booking_room
        if room
          booking_room.update(room: room, room_type: room.room_type)
        elsif selected_room_type_id.present?
          booking_room.update(room_type_id: selected_room_type_id)
        end
      end

      redirect_to admin_booking_path(@booking),
        notice: "Booking updated."
    else
      set_room_types
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @booking.destroy

    redirect_to admin_bookings_path,
      notice: "Booking deleted."
  end

  def confirm
    @booking.confirm!

    redirect_to admin_booking_path(@booking),
      notice: "Booking confirmed."
  end

  def check_in
    @booking.check_in!

    redirect_to admin_booking_path(@booking),
      notice: "Guest checked in."
  end

  def check_out
    @booking.check_out!

    redirect_to admin_booking_path(@booking),
      notice: "Guest checked out."
  end

  def cancel
    @booking.cancel!(reason: params[:reason])

    redirect_to admin_booking_path(@booking),
      notice: "Booking cancelled."
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
    # Determine selected room type from existing booking_rooms if present
    @selected_room_type_id = @booking.booking_rooms.first&.room_type_id
  end

  def set_room_types
    @room_types = RoomType.includes(:rooms).ordered
  end

  # Parameters used by the GET "Update price" request.
  #
  # These are not being used to create a database record.
  # They are only used to redisplay the form with calculated values.
  def booking_form_params
    params.fetch(:booking, {}).permit(
      :check_in_date,
      :check_out_date,
      :room_number,
      :room_type_id,
      :num_adults,
      :num_children,
      :special_requests,
      :payment_status,
      guest: [
        :first_name,
        :last_name,
        :email,
        :phone,
        :nationality
      ]
    )
  end

  def booking_params
    params.require(:booking).permit(
      :check_in_date,
      :check_out_date,
      :room_number,
      :room_type_id,
      :num_adults,
      :num_children,
      :special_requests,
      :payment_status,
      :total_amount,
      guest: [
        :first_name,
        :last_name,
        :email,
        :phone,
        :nationality
      ]
    )
  end

  def booking_update_params
    params.require(:booking).permit(
      :check_in_date,
      :check_out_date,
      :room_type_id,
      :room_number,
      :special_requests,
      :payment_status,
      :paid_amount,
      :payment_method,
      :total_amount
    )
  end

  # Calculates price for the "Update price" action.
  #
  # This is intentionally server-side Rails logic.
  def calculate_booking_price
    @room_type = RoomType.find_by(id: @selected_room_type_id)

    unless @room_type
      @calculation_error = "Please select a room type."
      return
    end

    begin
      @check_in = Date.parse(@selected_check_in.to_s)
      @check_out = Date.parse(@selected_check_out.to_s)
    rescue ArgumentError, TypeError
      @calculation_error =
        "Please enter valid check-in and check-out dates."
      return
    end

    if @check_in < Date.today
      @calculation_error =
        "Check-in date cannot be in the past."
      return
    end

    if @check_out <= @check_in
      @calculation_error =
        "Check-out date must be after check-in date."
      return
    end

    @nights = (@check_out - @check_in).to_i
    @price = @room_type.price_for(@check_in)
    @total = @price * @nights

    # Put calculated values into the form's booking object.
    @booking.total_amount = @total
  end

  # Rebuild the objects needed by new.html.erb after
  # a validation failure during create.
  def prepare_create_form
    @booking ||= Booking.new
    @guest ||= Guest.new

    @booking.assign_attributes(
      num_adults: booking_params[:num_adults].presence || 1,
      num_children: booking_params[:num_children].presence || 0,
      payment_status: booking_params[:payment_status].presence || "unpaid",
      special_requests: booking_params[:special_requests]
    )

    @guest = Guest.new(booking_params[:guest] || {}) unless @guest.persisted?

    @room_type = RoomType.find_by(id: booking_params[:room_type_id])

    if @room_type && @check_in && @check_out
      @nights = (@check_out - @check_in).to_i
      @price = @room_type.price_for(@check_in)
      @total = @price * @nights
    end
  end
end
