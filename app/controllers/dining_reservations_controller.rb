class DiningReservationsController < ApplicationController
  skip_before_action :require_authentication

  def new
    @dining_reservation = DiningReservation.new
  end

  def create
    @dining_reservation = DiningReservation.new(dining_reservation_params)
    @dining_reservation.status = "pending"

    if @dining_reservation.save
      redirect_to dining_reservation_path(@dining_reservation), notice: "Reservation submitted successfully! We'll confirm shortly."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @dining_reservation = DiningReservation.find(params[:id])
  end

  private

  def dining_reservation_params
    params.require(:dining_reservation).permit(:name, :email, :phone, :reservation_date, :reservation_time, :number_of_guests, :special_requests)
  end
end
