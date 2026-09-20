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
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :phone,
            presence: true,
            format: {
              with: /\A\+?[0-9 \-()]{7,25}\z/,
              message: "only allows digits, spaces, hyphens, parentheses and optional +"
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

  def self.find_by_or_create_by_email(attrs)
    guest = find_or_initialize_by(email: attrs[:email])
    guest.assign_attributes(attrs) if guest.new_record?
    guest
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
