class Guest < ApplicationRecord
  # Prevent deleting a guest that has associated bookings (DB requires guest_id)
  has_many :bookings, dependent: :restrict_with_error
  # Reviews can be nullified if needed
  has_many :reviews, dependent: :nullify

  validates :first_name, :last_name,
            presence: true,
            length: { maximum: 50 },
            format: {
              with: /\A[a-zA-Z '.-]+\z/,
              message: "only allows letters, spaces, hyphens, dots and apostrophes"
            }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :phone,
            presence: true,
            format: {
              with: /\A\+?[0-9\s\-]{7,15}\z/,
              message: "only allows digits, spaces, hyphens, optional +"
            }
  validates :nationality,
            presence: true,
            length: { maximum: 50 },
            format: {
              with: /\A[a-zA-Z\s'-]+\z/,
              message: "only allows letters, spaces, hyphens and apostrophes"
            }

  before_validation :normalize_email

  def full_name
    "#{first_name} #{last_name}"
  end

  def total_stays
    bookings.checked_out.count
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
