import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roomType", "roomNumber", "rate", "totalAmount"]

  connect() {
    this.checkInEl = this.element.querySelector('[name="booking[check_in_date]"]')
    this.checkOutEl = this.element.querySelector('[name="booking[check_out_date]"]')
    this.roomSelect = this.element.querySelector('select[name="booking[room_type_id]"]')
    this.roomNumberSelect = this.hasRoomNumberTarget ? this.roomNumberTarget : this.element.querySelector('select[name="booking[room_number]"]')

    if (this.checkInEl) {
      this.checkInEl.addEventListener('change', () => {
        this.updateTotal()
        this.fetchAvailableRooms()
      })
      this.checkInEl.addEventListener('input', () => this.updateTotal())
    }
    if (this.checkOutEl) {
      this.checkOutEl.addEventListener('change', () => {
        this.updateTotal()
        this.fetchAvailableRooms()
      })
      this.checkOutEl.addEventListener('input', () => this.updateTotal())
    }
    if (this.roomSelect) {
      this.roomSelect.addEventListener('change', () => this.roomTypeChanged({ target: this.roomSelect }))
    }

    this.ratesMap = {}
    this.roomOptionsByType = {}
    if (this.roomSelect) {
      const raw = this.roomSelect.dataset.roomRates || this.roomSelect.getAttribute('data-room-rates')
      if (raw) {
        try { this.ratesMap = JSON.parse(raw) } catch (e) { this.ratesMap = {} }
      }

      const roomOptionsRaw = this.element.dataset.bookingFormRoomOptionsByType || this.element.getAttribute('data-booking-form-room-options-by-type')
      if (roomOptionsRaw) {
        try { this.roomOptionsByType = JSON.parse(roomOptionsRaw) } catch (e) { this.roomOptionsByType = {} }
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

    this.syncRoomNumbers()
    this.updateTotal()
  }

  roomTypeChanged(event) {
    const select = event.target || this.roomSelect
    const rate = parseFloat(this.ratesMap?.[select.value] || 0)
    if (this.hasRateTarget) this.rateTarget.value = rate
    this.updateTotal()
    
    // Fetch available rooms for the selected room type
    this.fetchAvailableRooms()
  }

  fetchAvailableRooms() {
    const roomTypeId = this.roomSelect?.value
    if (!roomTypeId) {
      this.syncRoomNumbers()
      return
    }

    const checkIn = this.checkInEl?.value
    const checkOut = this.checkOutEl?.value

    if (!checkIn || !checkOut) {
      this.syncRoomNumbers()
      return
    }

    // Make AJAX request to fetch available rooms
    const formData = new FormData()
    formData.append('room_type_id', roomTypeId)
    formData.append('check_in_date', checkIn)
    formData.append('check_out_date', checkOut)

    fetch('/admin/bookings/available-rooms', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      },
      body: formData
    })
      .then(response => response.json())
      .then(data => {
        if (data.rooms && Array.isArray(data.rooms)) {
          this.roomOptionsByType[roomTypeId] = data.rooms
          this.syncRoomNumbers()
        }
      })
      .catch(err => {
        console.error('Error fetching available rooms:', err)
        this.syncRoomNumbers()
      })
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

  syncRoomNumbers() {
    if (!this.roomNumberSelect || !this.roomSelect) return

    const selectedRoomTypeId = this.roomSelect.value
    const rooms = this.roomOptionsByType?.[selectedRoomTypeId] || []
    const currentValue = this.roomNumberSelect.value

    this.roomNumberSelect.innerHTML = ''

    const placeholder = document.createElement('option')
    placeholder.value = ''
    placeholder.textContent = 'Select room #'
    this.roomNumberSelect.appendChild(placeholder)

    rooms.forEach((room) => {
      const option = document.createElement('option')
      option.value = room.room_number
      option.textContent = room.room_number
      this.roomNumberSelect.appendChild(option)
    })

    this.roomNumberSelect.disabled = rooms.length === 0

    if (rooms.some((room) => room.room_number === currentValue)) {
      this.roomNumberSelect.value = currentValue
    } else {
      this.roomNumberSelect.value = ''
    }
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
