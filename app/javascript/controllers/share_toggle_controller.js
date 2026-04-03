import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["expanded", "compact"]

  hide() {
    this.expandedTarget.classList.add("hidden")
    this.compactTarget.classList.remove("hidden")
  }

  show() {
    this.expandedTarget.classList.remove("hidden")
    this.compactTarget.classList.add("hidden")
  }
}
