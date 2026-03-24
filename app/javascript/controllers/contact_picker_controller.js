import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "name", "suggestions", "linkedBadge"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
    this.selectedContactId = null
  }

  disconnect() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
  }

  onEmailInput() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    const query = this.emailTarget.value.trim()

    if (query.length < 2) {
      this.hideSuggestions()
      this.clearLinkedBadge()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchContacts(query), 250)
  }

  async fetchContacts(query) {
    try {
      const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) return
      const contacts = await response.json()
      this.showSuggestions(contacts)
    } catch (e) {
      console.error("Contact search failed:", e)
    }
  }

  showSuggestions(contacts) {
    if (!this.hasSuggestionsTarget) return

    if (contacts.length === 0) {
      this.hideSuggestions()
      return
    }

    this.suggestionsTarget.innerHTML = contacts.map(c => `
      <button type="button"
              class="w-full text-left px-3 py-2 hover:bg-blue-50 transition-colors cursor-pointer"
              data-action="click->contact-picker#selectContact"
              data-contact-id="${c.id}"
              data-contact-email="${this.escapeHtml(c.email || '')}"
              data-contact-name="${this.escapeHtml(c.name || '')}"
              data-contact-company="${this.escapeHtml(c.company || '')}"
              data-contact-title="${this.escapeHtml(c.title || '')}">
        <div class="text-sm font-medium text-gray-900">${this.escapeHtml(c.name)}</div>
        <div class="text-xs text-gray-500">${this.escapeHtml(c.email)}${c.company ? ' · ' + this.escapeHtml(c.company) : ''}</div>
      </button>
    `).join('')

    this.suggestionsTarget.classList.remove("hidden")
  }

  hideSuggestions() {
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.classList.add("hidden")
      this.suggestionsTarget.innerHTML = ""
    }
  }

  selectContact(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const email = btn.dataset.contactEmail
    const name = btn.dataset.contactName
    const contactId = btn.dataset.contactId

    if (this.hasEmailTarget && email) this.emailTarget.value = email
    if (this.hasNameTarget && name) this.nameTarget.value = name

    this.selectedContactId = contactId
    this.showLinkedBadge(name)
    this.hideSuggestions()
  }

  showLinkedBadge(name) {
    if (!this.hasLinkedBadgeTarget) return
    this.linkedBadgeTarget.innerHTML = `
      <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
        <svg class="h-3 w-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-1.102-4.243a4 4 0 015.656 0l4 4a4 4 0 01-5.656 5.656l-1.1-1.1"/></svg>
        Linked to ${this.escapeHtml(name)}
      </span>
    `
    this.linkedBadgeTarget.classList.remove("hidden")
  }

  clearLinkedBadge() {
    if (this.hasLinkedBadgeTarget) {
      this.linkedBadgeTarget.innerHTML = ""
      this.linkedBadgeTarget.classList.add("hidden")
    }
    this.selectedContactId = null
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text || ''
    return div.innerHTML
  }
}
