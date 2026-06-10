class Admin::DiningReservationsController < ApplicationController
  before_action :set_dining_reservation, only: [:show, :confirm, :cancel, :complete]

  def index
    @dining_reservations = DiningReservation.upcoming
  end

  def show
  end

  def confirm
    @dining_reservation.update(status: "confirmed")
    redirect_to admin_dining_reservation_path(@dining_reservation), notice: "Reservation has been confirmed."
  end

  def cancel
    @dining_reservation.update(status: "cancelled")
    redirect_to admin_dining_reservation_path(@dining_reservation), notice: "Reservation has been cancelled."
  end

  def complete
    @dining_reservation.update(status: "completed")
    redirect_to admin_dining_reservation_path(@dining_reservation), notice: "Reservation has been marked as completed."
  end

  private

  def set_dining_reservation
    @dining_reservation = DiningReservation.find(params[:id])
  end
end
