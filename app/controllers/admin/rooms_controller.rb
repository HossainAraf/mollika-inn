class Admin::RoomsController < Admin::BaseController
  before_action :set_room, only: [ :show, :edit, :update, :destroy ]

  def index
    @rooms = Room
      .preload(:room_type, active_bookings: :guest)
      .order(:room_number)

    requested_status = params[:status].presence
    if requested_status.present? && Room::STATUSES.include?(requested_status)
      @rooms = @rooms.where(status: requested_status)
    end

    @room_status_counts = Room.group(:status).count
  end

  def new
    @room = Room.new
    @room_types = RoomType.ordered
  end

  def show
  end

  def create
    @room = Room.new(room_params)
    if @room.save
      redirect_to admin_rooms_path, notice: "Room created."
    else
      @room_types = RoomType.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @room_types = RoomType.ordered
  end

  def update
    if @room.update(room_params)
      redirect_to admin_rooms_path, notice: "Room updated."
    else
      @room_types = RoomType.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @room.destroy
    redirect_to admin_rooms_path, notice: "Room deleted."
  end

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:room_type_id, :room_number, :floor, :status, :notes)
  end
end
