class Admin::FacilitiesController < Admin::BaseController
  before_action :set_facility, only: [ :show, :edit, :update, :destroy ]

  def index
    @facilities = Facility.ordered
  end

  def show
  end

  def new
    @facility = Facility.new
  end

  def create
    @facility = Facility.new(facility_params)
    if @facility.save
      redirect_to admin_facility_path(@facility), notice: "Facility created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @facility.update(facility_params)
      redirect_to admin_facility_path(@facility), notice: "Facility updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @facility.destroy
    redirect_to admin_facilities_path, notice: "Facility deleted."
  end

  private

  def set_facility
    @facility = Facility.find(params[:id])
  end

  def facility_params
    params.require(:facility).permit(:name, :description, :icon_name, :category, :position, :visible)
  end
end
