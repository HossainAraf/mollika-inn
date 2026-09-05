class RoomType < ApplicationRecord
  FALLBACK_PHOTO_URLS = {
    "single-room" => "https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80",
    "double-room" => "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80",
    "deluxe-room" => "https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800&q=80",
    "family-room" => "https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800&q=80"
  }.freeze

  has_many :rooms, dependent: :destroy
  has_many :rates, dependent: :destroy
  has_many :booking_rooms, dependent: :destroy
  has_many_attached :photos

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :size_sqm, numericality: { greater_than: 0 }, allow_nil: true
  validates :slug, presence: true, uniqueness: true
  validates :base_price_per_night, numericality: { greater_than: 0 }
  validates :max_occupancy, numericality: { greater_than: 0 }

  before_validation :generate_slug, on: :create

  # scope :visible, -> {
  #   column_names.include?("visible") ? where(visible: true) : all
  # }
  # Replace the visible scope with this:
  scope :visible, -> { all }  # Returns all records since no visible column
  scope :ordered, -> { order(:name) }

  def to_param
    slug
  end

  def default_photo_url
    FALLBACK_PHOTO_URLS.fetch(slug, "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80")
  end

  def primary_photo_url
    return rails_blob_url(photos.first) if photos.attached?

    default_photo_url
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

  after_commit :propagate_price_change, on: :update

  def propagate_price_change
    # Only propagate when base price changed; rates changes handled in Rate model
    return unless saved_change_to_base_price_per_night?

    # If there are default rates (priority 0) that act as fallbacks, keep them in sync
    rates.where(priority: 0).find_each do |r|
      next if r.price_per_night == base_price_per_night
      r.update!(price_per_night: base_price_per_night)
    end

    update_future_bookings
  rescue StandardError => e
    Rails.logger.error("[RoomType] propagate_price_change failed for #{id}: #{e.message}")
  end

  def update_future_bookings
    cutoff = Date.current
    bookings = Booking.joins(:booking_rooms)
                      .where(booking_rooms: { room_type_id: id })
                      .where(status: %w[pending confirmed])
                      .where("check_out_date >= ?", cutoff)
                      .distinct

    bookings.find_each do |booking|
      ActiveRecord::Base.transaction do
        booking.booking_rooms.where(room_type_id: id).each do |br|
          new_rate = price_for(booking.check_in_date)
          next if br.rate_per_night == new_rate

          br.update!(rate_per_night: new_rate, total_amount: new_rate * booking.nights)
        end
        booking.update!(total_amount: booking.booking_rooms.sum(:total_amount))
      end
    end
  end

  private

  def generate_slug
    self.slug ||= name.to_s.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, "") if name.present?
  end
end
