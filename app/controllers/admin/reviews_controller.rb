class Admin::ReviewsController < Admin::BaseController
  before_action :set_review, only: [ :show, :edit, :update, :destroy, :approve ]

  def index
    @reviews = Review.includes(:guest, :booking).order(created_at: :desc)
  end

  def show
  end

  def new
    redirect_to admin_reviews_path, alert: "Reviews are created by guests."
  end

  def create
    redirect_to admin_reviews_path, alert: "Reviews are created by guests."
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to admin_review_path(@review), notice: "Review updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to admin_reviews_path, notice: "Review deleted."
  end

  def approve
    @review.update(approved: true)
    redirect_to admin_review_path(@review), notice: "Review approved."
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end

  def review_params
    params.require(:review).permit(:rating, :title, :body, :cleanliness_rating, :service_rating, :value_rating, :approved)
  end
end
