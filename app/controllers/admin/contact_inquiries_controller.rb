class Admin::ContactInquiriesController < Admin::BaseController
  before_action :set_inquiry, only: [ :show, :update, :destroy ]

  def index
    @contact_inquiries = ContactInquiry.order(created_at: :desc)
  end

  def show
  end

  def update
    if @inquiry.update(inquiry_params)
      redirect_to admin_contact_inquiry_path(@inquiry), notice: "Inquiry updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @inquiry.destroy
    redirect_to admin_contact_inquiries_path, notice: "Inquiry deleted."
  end

  private

  def set_inquiry
    @inquiry = ContactInquiry.find(params[:id])
  end

  def inquiry_params
    params.require(:contact_inquiry).permit(:status, :replied_at)
  end
end
