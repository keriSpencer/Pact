import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "input", "typedInput", "modeToggle", "drawMode", "typeMode", "clearBtn", "preview"]
  static values = { mode: { type: String, default: "draw" } }

  connect() {
    this.drawing = false
    this.lastPoint = null

    if (this.hasCanvasTarget) {
      this.setupCanvas()
    }
  }

  setupCanvas() {
    const canvas = this.canvasTarget
    const rect = canvas.parentElement.getBoundingClientRect()
    const dpr = window.devicePixelRatio || 1

    canvas.width = Math.min(rect.width - 4, 500) * dpr
    canvas.height = 150 * dpr
    canvas.style.width = `${Math.min(rect.width - 4, 500)}px`
    canvas.style.height = "150px"

    this.ctx = canvas.getContext("2d")
    this.ctx.scale(dpr, dpr)
    this.ctx.strokeStyle = "#1a1a6e"
    this.ctx.lineWidth = 2.5
    this.ctx.lineCap = "round"
    this.ctx.lineJoin = "round"

    // Mouse events
    canvas.addEventListener("mousedown", this.startDraw.bind(this))
    canvas.addEventListener("mousemove", this.draw.bind(this))
    canvas.addEventListener("mouseup", this.endDraw.bind(this))
    canvas.addEventListener("mouseleave", this.endDraw.bind(this))

    // Touch events
    canvas.addEventListener("touchstart", this.startDrawTouch.bind(this), { passive: false })
    canvas.addEventListener("touchmove", this.drawTouch.bind(this), { passive: false })
    canvas.addEventListener("touchend", this.endDraw.bind(this))
  }

  startDraw(e) {
    this.drawing = true
    const pos = this.getPosition(e)
    this.lastPoint = pos
    this.ctx.beginPath()
    this.ctx.moveTo(pos.x, pos.y)
  }

  draw(e) {
    if (!this.drawing) return
    const pos = this.getPosition(e)
    this.ctx.lineTo(pos.x, pos.y)
    this.ctx.stroke()
    this.lastPoint = pos
  }

  endDraw() {
    if (!this.drawing) return
    this.drawing = false
    this.lastPoint = null
    this.updateInput()
  }

  startDrawTouch(e) {
    e.preventDefault()
    const touch = e.touches[0]
    this.startDraw(touch)
  }

  drawTouch(e) {
    e.preventDefault()
    const touch = e.touches[0]
    this.draw(touch)
  }

  getPosition(e) {
    const rect = this.canvasTarget.getBoundingClientRect()
    return {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top
    }
  }

  clear() {
    if (!this.hasCanvasTarget) return
    const canvas = this.canvasTarget
    const dpr = window.devicePixelRatio || 1
    this.ctx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr)
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
    }
  }

  switchToDraw() {
    this.modeValue = "draw"
    if (this.hasDrawModeTarget) this.drawModeTarget.classList.remove("hidden")
    if (this.hasTypeModeTarget) this.typeModeTarget.classList.add("hidden")
    this.updateToggleStyles()
  }

  switchToType() {
    this.modeValue = "type"
    if (this.hasDrawModeTarget) this.drawModeTarget.classList.add("hidden")
    if (this.hasTypeModeTarget) this.typeModeTarget.classList.remove("hidden")
    this.updateToggleStyles()
  }

  updateToggleStyles() {
    if (!this.hasModeToggleTarget) return
    const buttons = this.modeToggleTarget.querySelectorAll("button")
    buttons.forEach(btn => {
      if (btn.dataset.mode === this.modeValue) {
        btn.classList.add("bg-blue-600", "text-white")
        btn.classList.remove("bg-white", "text-gray-700")
      } else {
        btn.classList.remove("bg-blue-600", "text-white")
        btn.classList.add("bg-white", "text-gray-700")
      }
    })
  }

  updateInput() {
    if (!this.hasInputTarget || !this.hasCanvasTarget) return
    this.inputTarget.value = this.canvasTarget.toDataURL("image/png")
  }

  updateFromTyped() {
    if (!this.hasInputTarget || !this.hasTypedInputTarget) return
    this.inputTarget.value = this.typedInputTarget.value
  }

  modeValueChanged() {
    this.updateToggleStyles()
  }
}
