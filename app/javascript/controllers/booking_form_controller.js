import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roomType", "rate", "totalAmount"]

  connect() {
    this.checkInEl = this.element.querySelector('[name="booking[check_in_date]"]')
    this.checkOutEl = this.element.querySelector('[name="booking[check_out_date]"]')
    this.roomSelect = this.element.querySelector('select[name="booking[room_type_id]"]')

    console.log('[booking-form] connected', { hasRateTarget: this.hasRateTarget, hasTotalAmountTarget: this.hasTotalAmountTarget, roomSelect: !!this.roomSelect })

    if (this.checkInEl) {
      this.checkInEl.addEventListener('change', () => this.updateTotal())
      this.checkInEl.addEventListener('input', () => this.updateTotal())
    }
    if (this.checkOutEl) {
      this.checkOutEl.addEventListener('change', () => this.updateTotal())
      this.checkOutEl.addEventListener('input', () => this.updateTotal())
    }
    if (this.roomSelect) {
      this.roomSelect.addEventListener('change', () => this.roomTypeChanged({ target: this.roomSelect }))
    }

    this.ratesMap = {}
    if (this.roomSelect) {
      const raw = this.roomSelect.dataset.roomRates || this.roomSelect.getAttribute('data-room-rates')
      if (raw) {
        try { this.ratesMap = JSON.parse(raw) } catch (e) { this.ratesMap = {} }
      }

      if (Object.keys(this.ratesMap).length === 0) {
        Array.from(this.roomSelect.options).forEach(opt => {
          if (opt.value) {
            const r = parseFloat(opt.dataset.rate || opt.getAttribute('data-rate') || 0)
            this.ratesMap[opt.value] = Number.isFinite(r) ? r : 0
          }
        })
      }

      const val = this.roomSelect.value
      const initRate = parseFloat(this.ratesMap[val] || 0)
      if (this.hasRateTarget) this.rateTarget.value = initRate
    }

    this.updateTotal()
  }

  roomTypeChanged(event) {
    const select = event.target || this.roomSelect
    const rate = parseFloat(this.ratesMap?.[select.value] || 0)
    if (this.hasRateTarget) this.rateTarget.value = rate
    this.updateTotal()
  }

  // Called externally if other inputs change
  refresh() { this.updateTotal() }

  updateTotal() {
    const checkIn = this.checkInEl?.value || ''
    const checkOut = this.checkOutEl?.value || ''
    const nights = this._nightsBetween(checkIn, checkOut)
    const currentRate = this.roomSelect ? parseFloat(this.ratesMap?.[this.roomSelect.value] || 0) : parseFloat(this.rateTarget?.value || 0)
    const rate = Number.isFinite(currentRate) ? currentRate : parseFloat(this.rateTarget?.value || 0)
    const total = nights > 0 ? (rate * nights) : 0

    if (this.hasRateTarget && this.roomSelect && this.roomSelect.value) {
      this.rateTarget.value = rate
    }
    if (this.hasTotalAmountTarget) this.totalAmountTarget.value = total
  }

  _nightsBetween(checkIn, checkOut) {
    if (!checkIn || !checkOut) return 0
    try {
      const d1 = new Date(checkIn)
      const d2 = new Date(checkOut)
      const diff = (d2 - d1) / (1000 * 60 * 60 * 24)
      return diff > 0 ? diff : 0
    } catch (e) { return 0 }
  }
}
