class Admin::RoomsController < Admin::BaseController
  before_action :set_room, only: [ :show, :edit, :update, :destroy ]

  def index
    @rooms = Room.includes(:room_type).ordered
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
