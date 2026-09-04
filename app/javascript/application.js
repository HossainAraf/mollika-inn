// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import BookingFormController from "controllers/booking_form_controller"
import "channels"

const application = Application.start()
application.register("booking-form", BookingFormController)
application.debug = false
window.Stimulus = application
