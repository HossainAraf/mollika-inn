import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "hamburger", "close"]

  toggle() {
    const open = !this.menuTarget.classList.contains("hidden")
    if (open) {
      this.menuTarget.classList.add("hidden")
      this.hamburgerTarget.classList.remove("hidden")
      this.closeTarget.classList.add("hidden")
    } else {
      this.menuTarget.classList.remove("hidden")
      this.hamburgerTarget.classList.add("hidden")
      this.closeTarget.classList.remove("hidden")
    }
  }
}
