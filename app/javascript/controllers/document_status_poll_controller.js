import { Controller } from "@hotwired/stimulus"

// Polls for document/envelope status changes and reloads when detected
// Starts fast (3s) for the first minute, then slows to 15s
export default class extends Controller {
  static values = {
    checkUrl: String
  }

  connect() {
    this.lastStatus = this.element.dataset.currentStatus || ""
    this.pollCount = 0
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  get currentInterval() {
    // Fast polling (3s) for first 20 checks (~60 seconds), then slow (15s)
    return this.pollCount < 20 ? 3000 : 15000
  }

  startPolling() {
    this.scheduleNext()
  }

  scheduleNext() {
    this.timer = setTimeout(() => this.checkForUpdates(), this.currentInterval)
  }

  stopPolling() {
    if (this.timer) clearTimeout(this.timer)
  }

  async checkForUpdates() {
    this.pollCount++
    try {
      const resp = await fetch(this.checkUrlValue, {
        headers: { "Accept": "application/json" }
      })
      if (!resp.ok) { this.scheduleNext(); return }

      const data = await resp.json()
      if (data.status !== this.lastStatus) {
        this.stopPolling()
        window.location.reload()
      } else {
        this.scheduleNext()
      }
    } catch {
      this.scheduleNext()
    }
  }
}
