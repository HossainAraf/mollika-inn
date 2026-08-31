require "test_helper"

class ConferenceReservationTest < ActiveSupport::TestCase
  test "it enqueues a confirmation email job after create" do
    reservation = ConferenceReservation.new(
      organization_name: "Acme Labs",
      contact_name: "Jane Doe",
      email: "jane@example.com",
      phone: "01700000000",
      event_date: Date.tomorrow,
      duration: "Full Day",
      attendees: 25,
      status: "pending"
    )

    calls = []
    ConferenceReservationConfirmationJob.singleton_class.send(:define_method, :perform_later) do |id|
      calls << id
    end

    reservation.save!

    assert_equal [ reservation.id ], calls
  ensure
    ConferenceReservationConfirmationJob.singleton_class.send(:remove_method, :perform_later)
  end

  test "confirmation job sends a Brevo email using the reservation email" do
    reservation = ConferenceReservation.create!(
      organization_name: "Acme Labs",
      contact_name: "Jane Doe",
      email: "jane@example.com",
      phone: "01700000000",
      event_date: Date.tomorrow,
      duration: "Full Day",
      attendees: 25,
      status: "pending"
    )

    sent = []
    BrevoMailer.singleton_class.send(:define_method, :send_email) do |to:, subject:, html_content:|
      sent << { to: to, subject: subject, html_content: html_content }
      true
    end

    ConferenceReservationConfirmationJob.new.perform(reservation.id)

    assert_equal [ "jane@example.com" ], sent.map { |m| m[:to] }
    assert_includes sent.first[:subject], "Conference Reservation"
    assert_includes sent.first[:html_content], "Acme Labs"
  ensure
    BrevoMailer.singleton_class.send(:remove_method, :send_email)
  end
end
