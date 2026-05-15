class ContactsController < ApplicationController
  skip_before_action :require_authentication

  def new
    @inquiry = ContactInquiry.new
  end

  def create
    @inquiry = ContactInquiry.new(inquiry_params)
    if @inquiry.save
      redirect_to contact_path, notice: "Thank you! We will get back to you soon."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def inquiry_params
    params.require(:contact_inquiry).permit(:name, :email, :phone, :subject, :message)
  end
end
