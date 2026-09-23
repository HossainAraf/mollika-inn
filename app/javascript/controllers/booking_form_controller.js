import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkIn", "checkOut", "checkInDisplay", "checkOutDisplay", "nights", "totalAmount", "bookingCheckIn", "bookingCheckOut"]

  connect() {
    this.updateTotal()
  }

  updateTotal() {
  const checkIn = new Date(this.checkInTarget.value)
  const checkOut = new Date(this.checkOutTarget.value)

  const nights = Math.max(
    0,
    Math.round((checkOut - checkIn) / (1000 * 60 * 60 * 24))
  )

  const rate = Number(this.element.dataset.rate || 0)
  const total = nights * rate

  this.checkInDisplayTarget.textContent = this.formatDate(checkIn)
  this.checkOutDisplayTarget.textContent = this.formatDate(checkOut)

  this.bookingCheckInTarget.value = this.checkInTarget.value
  this.bookingCheckOutTarget.value = this.checkOutTarget.value

  this.nightsTargets.forEach((element) => {
    element.textContent = `${nights} night${nights === 1 ? "" : "s"}`
  })

  this.totalAmountTargets.forEach((element) => {
    element.textContent = `৳${total.toLocaleString()}`
  })
}

formatDate(date) {
  return date.toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric"
  })
}
}