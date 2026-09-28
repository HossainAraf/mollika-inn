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
    existing_guest = find_by(email: attrs[:email])

    return existing_guest if existing_guest

    new(
      email: attrs[:email],
      first_name: attrs[:first_name],
      last_name: attrs[:last_name],
      phone: attrs[:phone],
      nationality: attrs[:nationality],
      address: attrs[:address],
      nid_or_passport: attrs[:nid_or_passport]
    )
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
