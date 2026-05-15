class Review < ApplicationRecord
  belongs_to :booking
  belongs_to :guest

  validates :rating, numericality: { in: 1..5 }
  validates :body, presence: true
  validates :booking_id, uniqueness: { message: "already has a review" }

  scope :approved, -> { where(approved: true) }
  scope :pending,  -> { where(approved: false) }
  scope :recent,   -> { order(created_at: :desc) }

  def average_sub_rating
    scores = [cleanliness_rating, service_rating, value_rating].compact
    scores.any? ? (scores.sum.to_f / scores.size).round(1) : rating
  end
end
