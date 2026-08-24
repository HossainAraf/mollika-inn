class Admin::ConferenceReservationsController < Admin::BaseController
  before_action :set_reservation, only: [ :show, :confirm, :cancel, :destroy ]

  def index
    @conference_reservations = ConferenceReservation.order(event_date: :asc)
  end

  def show
  end

  def confirm
    @reservation.update(status: "confirmed")
    redirect_to admin_conference_reservation_path(@reservation), notice: "Reservation confirmed."
  end

  def cancel
    @reservation.update(status: "cancelled")
    redirect_to admin_conference_reservation_path(@reservation), notice: "Reservation cancelled."
  end

  def destroy
    @reservation.destroy
    redirect_to admin_conference_reservations_path, notice: "Reservation deleted."
  end

  private

  def set_reservation
    @reservation = ConferenceReservation.find(params[:id])
  end
end
