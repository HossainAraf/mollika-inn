class Admin::AvailabilitiesController < Admin::BaseController
  before_action :set_room

  def index
    @availabilities = @room.availabilities.order(blocked_date: :asc)
  end

  def create
    availability = @room.availabilities.new(availability_params)
    if availability.save
      redirect_to admin_room_availabilities_path(@room), notice: "Blocked date added."
    else
      redirect_to admin_room_availabilities_path(@room), alert: availability.errors.full_messages.to_sentence
    end
  end

  def destroy
    availability = @room.availabilities.find(params[:id])
    availability.destroy
    redirect_to admin_room_availabilities_path(@room), notice: "Blocked date removed."
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def availability_params
    params.require(:availability).permit(:blocked_date, :reason)
  end
end
