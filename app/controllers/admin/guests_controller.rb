class Admin::GuestsController < Admin::BaseController
  before_action :set_guest, only: [ :show, :edit, :update, :destroy ]

  def index
    @guests = Guest.order(created_at: :desc)
  end

  def show
  end

    def new
      @guest = Guest.new
    end

    def create
      @guest = Guest.new(guest_params)
      if @guest.save
        redirect_to admin_guest_path(@guest), notice: "Guest created."
      else
        render :new, status: :unprocessable_entity
      end
    end

  def edit
  end

  def update
    if @guest.update(guest_params)
      redirect_to admin_guest_path(@guest), notice: "Guest updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @guest.destroy
    redirect_to admin_guests_path, notice: "Guest removed."
  end

  private

  def set_guest
    @guest = Guest.find(params[:id])
  end

  def guest_params
    params.require(:guest).permit(:first_name, :last_name, :email, :phone, :address, :nationality, :nid_or_passport)
  end
end
