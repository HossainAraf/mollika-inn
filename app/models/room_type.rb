class RoomType < ApplicationRecord
  has_many :rooms, dependent: :destroy
  has_many :rates, dependent: :destroy
  has_many :booking_rooms, dependent: :destroy
  has_many_attached :photos

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :base_price_per_night, numericality: { greater_than: 0 }
  validates :max_occupancy, numericality: { greater_than: 0 }

  before_validation :generate_slug, on: :create

  scope :visible, -> {
    column_names.include?("visible") ? where(visible: true) : all
  }
  scope :ordered, -> { order(:name) }

  def to_param
    slug
  end

  def available_rooms_count(check_in, check_out)
    rooms.where(status: "available").count -
      BookingRoom.joins(:booking)
                 .where(room_type: self)
                 .where(bookings: { status: %w[confirmed checked_in] })
                 .where("bookings.check_in_date < ? AND bookings.check_out_date > ?", check_out, check_in)
                 .count
  end

  def price_for(check_in_date)
    applicable_rate = rates.where("start_date <= ? AND end_date >= ?", check_in_date, check_in_date)
                           .order(priority: :desc)
                           .first
    applicable_rate ? applicable_rate.price_per_night : base_price_per_night
  end

  private

  def generate_slug
    self.slug ||= name.to_s.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, "") if name.present?
  end
end
