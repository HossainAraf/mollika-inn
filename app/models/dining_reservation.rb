class DiningReservation < ApplicationRecord
  STATUSES = %w[pending confirmed completed cancelled].freeze

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :reservation_date, presence: true
  validates :reservation_time, presence: true, numericality: { greater_than: 0, less_than: 2400 }
  validates :number_of_guests, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :upcoming, -> { where("reservation_date >= ?", Date.today).order(:reservation_date, :reservation_time) }
  scope :by_status, ->(status) { where(status: status) }
end
