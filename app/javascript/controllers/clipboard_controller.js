import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const text = this.sourceTarget.value || this.sourceTarget.textContent
    try {
      await navigator.clipboard.writeText(text)
      this.showCopied()
    } catch {
      // Fallback for older browsers / mobile
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()
    try {
      document.execCommand("copy")
      this.showCopied()
    } catch {
      // Last resort
      prompt("Copy this link:", text)
    }
    document.body.removeChild(textarea)
  }

  showCopied() {
    if (!this.hasButtonTarget) return
    const original = this.buttonTarget.textContent
    this.buttonTarget.textContent = "Copied!"
    setTimeout(() => { this.buttonTarget.textContent = original }, 2000)
  }
}
