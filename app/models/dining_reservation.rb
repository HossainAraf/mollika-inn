class DiningReservation < ApplicationRecord
  before_validation :set_default_status, on: :create
  after_create_commit :enqueue_confirmation_job
  after_create_commit :enqueue_admin_notification_job

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

  private

  def set_default_status
    self.status = "pending" if status.blank?
  end

  def enqueue_confirmation_job
    DiningReservationConfirmationJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error("[DiningReservation] confirmation job enqueue failed: #{e.message}")
    DiningReservationConfirmationJob.perform_now(id)
  end

  def enqueue_admin_notification_job
    AdminDiningReservationNotificationJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error("[DiningReservation] admin notification job enqueue failed: #{e.message}")
    AdminDiningReservationNotificationJob.perform_now(id)
  end
end
