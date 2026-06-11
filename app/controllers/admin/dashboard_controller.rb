class Admin::DashboardController < Admin::BaseController
  def index
    @today_arrivals   = Booking.today_arrivals.includes(:guest).limit(10)
    @today_departures = Booking.today_departures.includes(:guest).limit(10)
    @pending_bookings = Booking.pending.includes(:guest).order(created_at: :desc).limit(10)
    @unread_inquiries = ContactInquiry.unread.count
    @pending_reviews  = Review.pending.count
    @occupancy_data   = occupancy_by_room_type
    @recent_bookings  = Booking.includes(:guest).order(created_at: :desc).limit(5)
    @revenue_this_week = revenue_for_period(Date.today.beginning_of_week, Date.today)
    @revenue_last_week = revenue_for_period(Date.today.last_week.beginning_of_week, Date.today.last_week.end_of_week)
  end

  private

  def occupancy_by_room_type
    RoomType.all.map do |rt|
      total = rt.rooms.count
      occupied = rt.rooms.where(status: "occupied").count
      { name: rt.name, total: total, occupied: occupied, pct: total > 0 ? (occupied.to_f / total * 100).round : 0 }
    end
  end

  def revenue_for_period(start_date, end_date)
    bookings = Booking.where(status: %w[confirmed checked_in checked_out])
                      .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    grouped = bookings.group_by { |b| b.created_at.to_date }
    (start_date..end_date).each_with_object({}) do |date, hash|
      hash[date] = (grouped[date]&.sum { |b| b.total_amount.to_f } || 0.0)
    end
  end
end
