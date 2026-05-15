class ReviewsController < ApplicationController
  skip_before_action :require_authentication

  def new
    @booking = Booking.find_by(id: params[:booking_id])
    @review  = Review.new
  end

  def create
    @booking = Booking.find(params[:review][:booking_id])
    @review  = Review.new(review_params.merge(booking: @booking, guest: @booking.guest, approved: false))
    if @review.save
      redirect_to root_path, notice: "Thank you for your review!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def review_params
    params.require(:review).permit(:booking_id, :rating, :title, :body,
                                   :cleanliness_rating, :service_rating, :value_rating)
  end
end
