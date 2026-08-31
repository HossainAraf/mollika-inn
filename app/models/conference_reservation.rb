class ConferenceReservation < ApplicationRecord
  before_validation :set_default_status, on: :create
  after_create_commit :enqueue_confirmation_job

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

  private

  def set_default_status
    self.status = "pending" if status.blank?
  end

  def enqueue_confirmation_job
    ConferenceReservationConfirmationJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error("[ConferenceReservation] confirmation job enqueue failed: #{e.message}")
    ConferenceReservationConfirmationJob.perform_now(id)
  end
end
