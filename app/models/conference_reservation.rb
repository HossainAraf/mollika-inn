class ConferenceReservation < ApplicationRecord
  DURATIONS = [ "Half Day", "Full Day", "Multi-Day" ].freeze

  validates :contact_name, :email, :event_date, :duration, :attendees, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :attendees, numericality: { only_integer: true, greater_than: 0 }

  def display_contact
    contact_name.presence || organization_name.presence || "—"
  end
end
