import { Controller } from "@hotwired/stimulus"

// Polls for document/envelope status changes and reloads when detected
export default class extends Controller {
  static values = {
    interval: { type: Number, default: 15000 }, // 15 seconds
    checkUrl: String
  }

  connect() {
    this.lastStatus = this.element.dataset.currentStatus || ""
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.timer = setInterval(() => this.checkForUpdates(), this.intervalValue)
  }

  stopPolling() {
    if (this.timer) clearInterval(this.timer)
  }

  async checkForUpdates() {
    try {
      const resp = await fetch(this.checkUrlValue, {
        headers: { "Accept": "application/json" }
      })
      if (!resp.ok) return

      const data = await resp.json()
      if (data.status !== this.lastStatus) {
        // Status changed — reload the page
        this.stopPolling()
        window.location.reload()
      }
    } catch {
      // Silently ignore network errors
    }
  }
}
