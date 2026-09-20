// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import BookingFormController from "controllers/booking_form_controller"

application.register("booking-form", BookingFormController)

eagerLoadControllersFrom("controllers", application)
