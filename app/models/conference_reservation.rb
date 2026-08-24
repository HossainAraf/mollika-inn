class ConferenceReservation < ApplicationRecord
  DURATIONS = [ "Half Day", "Full Day", "Multi-Day" ].freeze
  STATUSES = %w[pending confirmed cancelled].freeze

  validates :contact_name, :email, :event_date, :duration, :attendees, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :attendees, numericality: { only_integer: true, greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :upcoming, -> { where("event_date >= ?", Date.today).order(:event_date) }
  scope :by_status, ->(status) { where(status: status) }

  def display_contact
    contact_name.presence || organization_name.presence || "—"
  end
end
