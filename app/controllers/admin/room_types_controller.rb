class Admin::RoomTypesController < Admin::BaseController
  before_action :set_room_type, only: [:show, :edit, :update, :destroy]

  def index
    @room_types = RoomType.includes(:rooms).ordered
  end

  def show; end

  def new
    @room_type = RoomType.new
  end

  def create
    @room_type = RoomType.new(room_type_params)
    if @room_type.save
      redirect_to admin_room_types_path, notice: "Room type created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @room_type.update(room_type_params)
      redirect_to admin_room_types_path, notice: "Room type updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @room_type.destroy
    redirect_to admin_room_types_path, notice: "Room type deleted."
  end

  private

  def set_room_type
    @room_type = RoomType.find(params[:id])
  end

  def room_type_params
    params.require(:room_type).permit(
      :name, :description, :max_occupancy, :bed_type, :size_sqm,
      :base_price_per_night, :visible, amenities: [], photos: []
    )
  end
end
