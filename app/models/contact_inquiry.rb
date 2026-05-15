class ContactInquiry < ApplicationRecord
  STATUSES = %w[new read replied].freeze

  validates :name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: STATUSES }

  after_initialize { self.status ||= "new" }

  scope :unread, -> { where(status: "new") }
  scope :recent, -> { order(created_at: :desc) }
end
