import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    
    if (this.contentTarget.classList.contains("hidden")) {
      this.iconTarget.style.transform = "rotate(0deg)"
    } else {
      this.iconTarget.style.transform = "rotate(45deg)"
    }
  }
}

