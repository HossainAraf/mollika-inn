class MonthlyReportJob < ApplicationJob
  queue_as :default

  def perform
    start_date = Date.current.last_month.beginning_of_month
    end_date = Date.current.last_month.end_of_month

    @bookings_count = Booking.where(created_at: start_date.beginning_of_day..end_date.end_of_day).count
    @revenue = Booking.where(status: %w[confirmed checked_in checked_out])
                      .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                      .sum(:total_amount)
  end
end
