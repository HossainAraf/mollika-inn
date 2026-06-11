# Alternative to using a Database table for admin credentials, this model can be used to validate against credentials stored in Rails credentials or environment variables. This keeps the admin authentication logic simple and secure without needing to manage a separate database table for admins.
class Admin
  include ActiveModel::Model
  attr_accessor :email, :password

  # Keep this model strictly as a data structural placeholder if needed elsewhere
  def initialize(attributes = {})
    super
    @email = Rails.application.credentials.dig(:admin, :email) || ENV["ADMIN_EMAIL"]
    @password = Rails.application.credentials.dig(:admin, :password) || ENV["ADMIN_PASSWORD"]
  end
end
