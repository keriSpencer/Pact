import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.showTab("original")
  }

  switch(event) {
    event.preventDefault()
    const tab = event.currentTarget.dataset.tab
    this.showTab(tab)
  }

  showTab(tabName) {
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tab === tabName) {
        tab.classList.add("border-blue-500", "text-blue-600")
        tab.classList.remove("border-transparent", "text-gray-500")
      } else {
        tab.classList.remove("border-blue-500", "text-blue-600")
        tab.classList.add("border-transparent", "text-gray-500")
      }
    })

    this.panelTargets.forEach(panel => {
      if (panel.dataset.tab === tabName) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
