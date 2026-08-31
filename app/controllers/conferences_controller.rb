class ConferencesController < ApplicationController
  skip_before_action :require_authentication

  def new
    @reservation = ConferenceReservation.new
  end

  def create
    @reservation = ConferenceReservation.new(reservation_params)
    @reservation.status = "pending" if @reservation.status.blank?

    if @reservation.save
      redirect_to conference_thanks_path(@reservation), notice: "Reservation received. We'll contact you shortly."
    else
      flash.now[:alert] = "Please correct the errors and try again."
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @reservation = ConferenceReservation.find(params[:id])
  end

  private

  def reservation_params
    params.require(:conference_reservation).permit(
      :organization_name, :contact_name, :email, :phone,
      :event_date, :duration, :attendees, :package, :special_requests
    )
  end
end
