ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup fixtures in dependency-safe order (children before parents)
    # This prevents Postgres foreign-key violations when the test DB user
    # cannot disable referential integrity.
    # By default do not load fixtures automatically. Tests create their own
    # data (controllers/specs use factories or explicit creates). Loading
    # incomplete/empty fixtures (many test/fixtures/*.yml are placeholders)
    # can cause NOT NULL or FK violations in environments where the test
    # DB user cannot disable referential integrity. Avoid global fixture
    # loading to keep tests isolated and deterministic.
    # (No `fixtures` call here)

    # Add more helper methods to be used by all tests here...
  end
end

module AdminAuthTestHelper
  def login_as_admin
    email = Rails.application.credentials.dig(:admin, :email)
    password = Rails.application.credentials.dig(:admin, :password)

    raise "Admin credentials not set in Rails credentials" unless email && password

    post session_path, params: { email: email, password: password }
    assert_redirected_to admin_root_path
  end
end
