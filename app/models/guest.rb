class Guest < ApplicationRecord
  has_many :bookings, dependent: :nullify
  has_many :reviews, dependent: :nullify

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :phone, presence: true

  before_save { email.downcase! }

  def full_name
    "#{first_name} #{last_name}"
  end

  def total_stays
    bookings.checked_out.count
  end
end
