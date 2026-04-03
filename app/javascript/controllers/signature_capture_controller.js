import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "drawArea", "typeArea", "typeInput", "saveBtn"]
  static values = { type: String }

  connect() {
    this.mode = "draw"
    this.isDrawing = false
    this.initCanvas()
  }

  initCanvas() {
    const canvas = this.canvasTarget
    if (!canvas) return
    const rect = canvas.getBoundingClientRect()
    canvas.width = rect.width
    canvas.height = rect.height
    const ctx = canvas.getContext("2d")
    ctx.fillStyle = "#ffffff"
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    ctx.strokeStyle = "#1a1a1a"
    ctx.lineWidth = 2.5
    ctx.lineCap = "round"
    ctx.lineJoin = "round"

    canvas.addEventListener("mousedown", (e) => this.startDraw(e))
    canvas.addEventListener("mousemove", (e) => this.continueDraw(e))
    canvas.addEventListener("mouseup", () => this.endDraw())
    canvas.addEventListener("mouseleave", () => this.endDraw())
    canvas.addEventListener("touchstart", (e) => { e.preventDefault(); this.startDraw(e.touches[0]) })
    canvas.addEventListener("touchmove", (e) => { e.preventDefault(); this.continueDraw(e.touches[0]) })
    canvas.addEventListener("touchend", () => this.endDraw())
  }

  startDraw(e) {
    if (this.mode !== "draw") return
    this.isDrawing = true
    const rect = this.canvasTarget.getBoundingClientRect()
    const ctx = this.canvasTarget.getContext("2d")
    ctx.beginPath()
    ctx.moveTo(e.clientX - rect.left, e.clientY - rect.top)
  }

  continueDraw(e) {
    if (!this.isDrawing) return
    const rect = this.canvasTarget.getBoundingClientRect()
    const ctx = this.canvasTarget.getContext("2d")
    ctx.lineTo(e.clientX - rect.left, e.clientY - rect.top)
    ctx.stroke()
  }

  endDraw() { this.isDrawing = false }

  switchToDraw() {
    this.mode = "draw"
    this.drawAreaTarget.classList.remove("hidden")
    this.typeAreaTarget.classList.add("hidden")
    const btns = this.element.querySelectorAll(".sig-cap-mode-btn")
    btns[0].classList.add("bg-blue-600", "text-white")
    btns[0].classList.remove("bg-white", "dark:bg-gray-700", "text-gray-700", "dark:text-gray-300")
    btns[1].classList.remove("bg-blue-600", "text-white")
    btns[1].classList.add("bg-white", "dark:bg-gray-700", "text-gray-700", "dark:text-gray-300")
  }

  switchToType() {
    this.mode = "type"
    this.drawAreaTarget.classList.add("hidden")
    this.typeAreaTarget.classList.remove("hidden")
    const btns = this.element.querySelectorAll(".sig-cap-mode-btn")
    btns[1].classList.add("bg-blue-600", "text-white")
    btns[1].classList.remove("bg-white", "dark:bg-gray-700", "text-gray-700", "dark:text-gray-300")
    btns[0].classList.remove("bg-blue-600", "text-white")
    btns[0].classList.add("bg-white", "dark:bg-gray-700", "text-gray-700", "dark:text-gray-300")
    if (this.hasTypeInputTarget) this.typeInputTarget.focus()
  }

  clear() {
    if (this.mode === "draw") {
      const ctx = this.canvasTarget.getContext("2d")
      ctx.fillStyle = "#ffffff"
      ctx.fillRect(0, 0, this.canvasTarget.width, this.canvasTarget.height)
    } else if (this.hasTypeInputTarget) {
      this.typeInputTarget.value = ""
    }
  }

  async save() {
    let data
    if (this.mode === "draw") {
      // Check canvas has content
      const canvas = this.canvasTarget
      const ctx = canvas.getContext("2d")
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
      let hasContent = false
      for (let i = 0; i < imageData.data.length; i += 4) {
        if (imageData.data[i] < 250 || imageData.data[i+1] < 250 || imageData.data[i+2] < 250) {
          hasContent = true; break
        }
      }
      if (!hasContent) { alert("Please draw your " + this.typeValue + " first."); return }
      data = canvas.toDataURL("image/png")
    } else {
      data = this.typeInputTarget?.value?.trim()
      if (!data) { alert("Please type your " + this.typeValue + " first."); return }
    }

    const url = this.saveBtnTarget.dataset.url
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const paramName = this.typeValue === "initials" ? "initials_data" : "signature_data"

    this.saveBtnTarget.disabled = true
    this.saveBtnTarget.textContent = "Saving..."

    try {
      const form = document.createElement("form")
      form.method = "POST"
      form.action = url
      form.style.display = "none"

      const tokenInput = document.createElement("input")
      tokenInput.name = "authenticity_token"
      tokenInput.value = csrfToken
      form.appendChild(tokenInput)

      const dataInput = document.createElement("input")
      dataInput.name = paramName
      dataInput.value = data
      form.appendChild(dataInput)

      document.body.appendChild(form)
      form.submit()
    } catch {
      alert("Failed to save. Please try again.")
      this.saveBtnTarget.disabled = false
      this.saveBtnTarget.textContent = "Save " + this.typeValue.charAt(0).toUpperCase() + this.typeValue.slice(1)
    }
  }

  onTypeInput() {
    // Could show live preview if desired
  }
}
