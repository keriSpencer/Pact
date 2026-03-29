import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthlyContent", "annualContent", "monthlyBtn", "annualBtn"]
  static values = { default: { type: String, default: "monthly" } }

  connect() {
    if (this.defaultValue === "annual") {
      this.showAnnual()
    } else {
      this.showMonthly()
    }
  }

  showMonthly() {
    this.monthlyContentTargets.forEach(el => el.classList.remove("hidden"))
    this.annualContentTargets.forEach(el => el.classList.add("hidden"))
    this.monthlyBtnTarget.classList.add("bg-white", "text-gray-900", "shadow-sm")
    this.monthlyBtnTarget.classList.remove("text-gray-600")
    this.annualBtnTarget.classList.remove("bg-white", "text-gray-900", "shadow-sm")
    this.annualBtnTarget.classList.add("text-gray-600")
  }

  showAnnual() {
    this.annualContentTargets.forEach(el => el.classList.remove("hidden"))
    this.monthlyContentTargets.forEach(el => el.classList.add("hidden"))
    this.annualBtnTarget.classList.add("bg-white", "text-gray-900", "shadow-sm")
    this.annualBtnTarget.classList.remove("text-gray-600")
    this.monthlyBtnTarget.classList.remove("bg-white", "text-gray-900", "shadow-sm")
    this.monthlyBtnTarget.classList.add("text-gray-600")
  }
}
