class ContactMailer < ApplicationMailer
  def inquiry_received(inquiry)
    @inquiry = inquiry
    recipient = Setting.find_by(key: "hotel_email")&.value

    return if recipient.blank?

    mail to: recipient, subject: "New Contact Inquiry ##{@inquiry.id}"
  end
end
