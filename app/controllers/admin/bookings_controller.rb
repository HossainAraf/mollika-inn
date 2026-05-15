class Admin::BookingsController < Admin::BaseController
  before_action :set_booking, only: [ :show, :edit, :update, :destroy, :confirm, :check_in, :check_out, :cancel ]

  def index
    @bookings = Booking.includes(:guest, :room_types).order(created_at: :desc)
    @bookings = @bookings.where(status: params[:status]) if params[:status].present?
    @bookings = @bookings.where("check_in_date >= ?", Date.parse(params[:from])) if params[:from].present?
    @bookings = @bookings.where("check_out_date <= ?", Date.parse(params[:to])) if params[:to].present?
    @bookings = @bookings.page(params[:page]).per(20)
  end

  def new
    redirect_to admin_bookings_path, alert: "Create bookings from public booking form."
  end

  def create
    redirect_to admin_bookings_path, alert: "Create bookings from public booking form."
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
    params.require(:booking).permit(:special_requests, :payment_status, :paid_amount, :payment_method, :total_amount)
  end
end
