module Guests
  class BookingsController < ApplicationController
    skip_before_action :require_authentication
    before_action :require_guest_session
    before_action :set_booking, only: [ :show, :cancel ]

    def index
      @bookings = current_guest.bookings.includes(:room_types).order(created_at: :desc)
    end

    def show
    end

    def cancel
      @booking.cancel!(reason: params[:reason])
      redirect_to guests_booking_path(@booking), notice: "Booking cancelled."
    rescue ActiveRecord::RecordInvalid
      redirect_to guests_booking_path(@booking), alert: "This booking cannot be cancelled in its current state."
    end

    private

    def require_guest_session
      redirect_to new_guests_session_path, alert: "Please sign in." unless current_guest
    end

    def set_booking
      @booking = current_guest.bookings.find(params[:id])
    end
  end
end
