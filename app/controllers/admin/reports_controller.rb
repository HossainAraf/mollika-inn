require "csv"

class Admin::ReportsController < Admin::BaseController
  def index
  end

  def occupancy
    @total_rooms = Room.count
    @occupied_rooms = Room.where(status: "occupied").count
    @occupancy_percentage = if @total_rooms.zero?
      0
    else
      ((@occupied_rooms.to_f / @total_rooms) * 100).round(2)
    end
  end

  def revenue
    @total_revenue = Booking.where(status: %w[confirmed checked_in checked_out]).sum(:total_amount)
    @paid_revenue = Booking.sum(:paid_amount)
  end

  def bookings_export
    csv = CSV.generate(headers: true) do |rows|
      rows << [ "ID", "Guest", "Check In", "Check Out", "Status", "Total", "Paid" ]
      Booking.includes(:guest).find_each do |booking|
        rows << [
          booking.id,
          booking.guest&.full_name,
          booking.check_in_date,
          booking.check_out_date,
          booking.status,
          booking.total_amount,
          booking.paid_amount
        ]
      end
    end

    send_data csv, filename: "bookings-#{Date.today}.csv", type: "text/csv"
  end
end
