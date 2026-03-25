import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "canvas", "canvasContainer", "loadingState",
    "pageIndicator", "progressBar", "progressText",
    "fieldPanel", "reviewPanel", "reviewList", "submitButton"
  ]

  static values = {
    pdfUrl: String,
    signToken: String,
    fields: Array,
    signerName: { type: String, default: "" },
    signerEmail: { type: String, default: "" },
    captureArtifactUrl: String,
    completeFieldUrl: String,
    resetFieldUrl: String,
    finalizeUrl: String,
    successUrl: String
  }

  connect() {
    this.pdfDoc = null
    this.currentPage = 1
    this.totalPages = 1
    this.pdfCanvasImage = null
    this.currentFieldIndex = -1
    this.sigFields = JSON.parse(JSON.stringify(this.fieldsValue))
    this.drawingCanvas = null
    this.isDrawing = false
    this.drawMode = "draw"
    this.animationFrame = null
    this.pulsePhase = 0

    this.findFirstIncompleteField()
    this.updateProgress()
    this.loadPdf()
  }

  disconnect() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
    }
  }

  findFirstIncompleteField() {
    const idx = this.sigFields.findIndex(f => !f.completed)
    this.currentFieldIndex = idx >= 0 ? idx : (this.sigFields.length > 0 ? 0 : -1)
  }

  get currentField() {
    return this.currentFieldIndex >= 0 ? this.sigFields[this.currentFieldIndex] : null
  }

  get completedCount() {
    return this.sigFields.filter(f => f.completed).length
  }

  get totalCount() {
    return this.sigFields.length
  }

  // PDF Loading
  async loadPdf() {
    try {
      const pdfjsLib = await import("pdfjs-dist")
      pdfjsLib.GlobalWorkerOptions.workerSrc = "https://cdn.jsdelivr.net/npm/pdfjs-dist@4.0.379/build/pdf.worker.min.mjs"
      const loadingTask = pdfjsLib.getDocument(this.pdfUrlValue)
      this.pdfDoc = await loadingTask.promise
      this.totalPages = this.pdfDoc.numPages

      if (this.hasLoadingStateTarget) this.loadingStateTarget.classList.add("hidden")
      if (this.hasCanvasContainerTarget) this.canvasContainerTarget.classList.remove("hidden")

      const targetPage = this.currentField ? this.currentField.page : 1
      await this.renderPage(targetPage)
      this.showFieldInput(this.currentField)
      this.startPulseAnimation()
    } catch (error) {
      console.error("Error loading PDF:", error)
      if (this.hasLoadingStateTarget) {
        this.loadingStateTarget.innerHTML = '<div class="text-center text-red-600 py-8"><p>Failed to load document</p></div>'
      }
    }
  }

  async renderPage(pageNum) {
    if (!this.pdfDoc) return
    const page = await this.pdfDoc.getPage(pageNum)
    const containerWidth = Math.max((this.hasCanvasContainerTarget ? this.canvasContainerTarget.clientWidth : 600) - 40, 300)
    const viewport = page.getViewport({ scale: 1 })
    let scale = containerWidth / viewport.width
    if (viewport.height * scale > 700) scale = 700 / viewport.height
    scale = Math.min(scale, 1.5)

    const scaledViewport = page.getViewport({ scale })
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    canvas.width = scaledViewport.width
    canvas.height = scaledViewport.height

    await page.render({ canvasContext: ctx, viewport: scaledViewport }).promise
    this.currentPage = pageNum
    this.pdfCanvasImage = ctx.getImageData(0, 0, canvas.width, canvas.height)
    this.updatePageIndicator()
    this.drawFieldOverlays()
  }

  drawFieldOverlays() {
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    if (this.pdfCanvasImage) ctx.putImageData(this.pdfCanvasImage, 0, 0)

    this.sigFields.forEach((field, index) => {
      if (field.page !== this.currentPage) return
      const isCurrent = index === this.currentFieldIndex
      this.drawFieldOverlay(ctx, canvas, field, isCurrent)
    })
  }

  drawFieldOverlay(ctx, canvas, field, isCurrent) {
    const x = (field.x / 100) * canvas.width
    const y = (field.y / 100) * canvas.height
    const w = ((field.width || 20) / 100) * canvas.width
    const h = ((field.height || 6) / 100) * canvas.height
    const left = x - w / 2
    const top = y - h / 2

    if (field.completed) {
      // Show actual content instead of a checkmark
      ctx.strokeStyle = "#16a34a"
      ctx.lineWidth = 1.5
      ctx.setLineDash([])
      ctx.strokeRect(left, top, w, h)
      ctx.fillStyle = "rgba(255, 255, 255, 0.85)"
      ctx.fillRect(left, top, w, h)

      const value = field.artifact_value
      if (value && value.startsWith && value.startsWith("data:image/")) {
        // Drawn signature/initials — render the image
        this.drawImageInField(ctx, value, left, top, w, h)
      } else if (field.type === "checkbox") {
        // Checkmark for checkbox
        ctx.fillStyle = "#16a34a"
        ctx.font = `bold ${Math.min(h * 0.7, 18)}px sans-serif`
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText("\u2713", x, y)
      } else if (value) {
        // Text content (name, date, email, typed signature, etc.)
        ctx.fillStyle = "#1a1a1a"
        const fontSize = Math.min(h * 0.55, 14)
        const isSignatureType = field.type === "signature" || field.type === "initials"
        ctx.font = isSignatureType ? `italic ${fontSize}px 'Georgia', serif` : `${fontSize}px sans-serif`
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        // Truncate if too long
        let displayText = value
        const maxWidth = w - 8
        while (ctx.measureText(displayText).width > maxWidth && displayText.length > 3) {
          displayText = displayText.slice(0, -4) + "..."
        }
        ctx.fillText(displayText, x, y)
      } else {
        // Fallback checkmark if no artifact value
        ctx.fillStyle = "#16a34a"
        ctx.font = "bold 14px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText("\u2713", x, y)
      }
    } else if (isCurrent) {
      // Pulsing blue border
      const alpha = 0.4 + 0.4 * Math.sin(this.pulsePhase)
      ctx.strokeStyle = `rgba(37, 99, 235, ${0.6 + 0.4 * Math.sin(this.pulsePhase)})`
      ctx.lineWidth = 3
      ctx.setLineDash([])
      ctx.strokeRect(left, top, w, h)
      ctx.fillStyle = `rgba(37, 99, 235, ${alpha * 0.15})`
      ctx.fillRect(left, top, w, h)
      // Label
      ctx.fillStyle = "#2563eb"
      ctx.font = "bold 12px sans-serif"
      ctx.textAlign = "center"
      ctx.textBaseline = "middle"
      ctx.fillText(field.label || field.type, x, y)
    } else {
      // Gray dashed border
      ctx.strokeStyle = "#9ca3af"
      ctx.lineWidth = 1
      ctx.setLineDash([4, 4])
      ctx.strokeRect(left, top, w, h)
      ctx.setLineDash([])
      ctx.fillStyle = "rgba(156, 163, 175, 0.06)"
      ctx.fillRect(left, top, w, h)
    }
  }

  startPulseAnimation() {
    const animate = () => {
      this.pulsePhase += 0.06
      this.drawFieldOverlays()
      this.animationFrame = requestAnimationFrame(animate)
    }
    this.animationFrame = requestAnimationFrame(animate)
  }

  // Page navigation
  previousPage() {
    if (this.currentPage > 1) this.renderPage(this.currentPage - 1)
  }

  nextPage() {
    if (this.currentPage < this.totalPages) this.renderPage(this.currentPage + 1)
  }

  updatePageIndicator() {
    if (this.hasPageIndicatorTarget) {
      this.pageIndicatorTarget.textContent = `Page ${this.currentPage} of ${this.totalPages}`
    }
  }

  updateProgress() {
    const completed = this.completedCount
    const total = this.totalCount
    const pct = total > 0 ? Math.round((completed / total) * 100) : 0

    if (this.hasProgressTextTarget) {
      if (completed === total) {
        this.progressTextTarget.textContent = `All ${total} fields completed`
      } else {
        const currentNum = Math.min(completed + 1, total)
        this.progressTextTarget.textContent = `Field ${currentNum} of ${total}`
      }
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${pct}%`
    }
  }

  // Field input display
  showFieldInput(field) {
    if (!field || !this.hasFieldPanelTarget) return

    if (field.completed) {
      this.advanceToNextField()
      return
    }

    this.fieldPanelTarget.classList.remove("hidden")
    if (this.hasReviewPanelTarget) this.reviewPanelTarget.classList.add("hidden")

    // Navigate to the field's page if needed
    if (field.page !== this.currentPage) {
      this.renderPage(field.page)
    }

    const type = field.type
    let html = ""

    if (type === "signature" || type === "initials") {
      const label = type === "signature" ? "Sign Here" : "Initial Here"
      const placeholder = type === "signature" ? "Type your signature..." : "Type your initials..."
      html = `
        <div class="space-y-4">
          <div class="flex items-center justify-between">
            <h3 class="text-sm font-semibold text-gray-900">${label}</h3>
            <div class="flex rounded-lg overflow-hidden border border-gray-300">
              <button type="button" data-action="signing-stepper#switchToDraw"
                      class="stepper-draw-btn px-3 py-1 text-xs font-medium bg-blue-600 text-white cursor-pointer">Draw</button>
              <button type="button" data-action="signing-stepper#switchToType"
                      class="stepper-type-btn px-3 py-1 text-xs font-medium bg-white text-gray-700 cursor-pointer">Type</button>
            </div>
          </div>
          <div class="stepper-draw-mode">
            <canvas class="stepper-signing-canvas w-full border-2 border-dashed border-gray-300 rounded-lg cursor-crosshair touch-none"
                    style="height: min(180px, 25vh); background-color: #ffffff; color-scheme: light;"></canvas>
          </div>
          <div class="stepper-type-mode hidden">
            <input type="text" class="stepper-typed-input block w-full rounded-lg border-gray-300 text-xl py-3 px-4"
                   style="font-family: 'Brush Script MT', 'Segoe Script', cursive;"
                   placeholder="${placeholder}">
          </div>
          <div class="flex justify-between items-center">
            <button type="button" data-action="signing-stepper#clearPad"
                    class="text-sm text-gray-500 hover:text-gray-700 cursor-pointer">Clear</button>
            <button type="button" data-action="signing-stepper#completeCurrentField"
                    class="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium text-sm hover:bg-blue-700 transition-colors cursor-pointer">
              Apply ${field.label || type.charAt(0).toUpperCase() + type.slice(1)}
            </button>
          </div>
        </div>
      `
    } else if (type === "name") {
      html = `
        <div class="space-y-4">
          <h3 class="text-sm font-semibold text-gray-900">${field.label || "Print Name"}</h3>
          <input type="text" class="stepper-text-input block w-full rounded-lg border border-gray-300 text-sm py-2.5 px-3 focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                 value="${this.escapeHtml(this.signerNameValue)}"
                 placeholder="Enter your full name...">
          ${this.signerNameValue ? '<p class="text-xs text-gray-400">Pre-filled from your signing invitation</p>' : ''}
          <div class="flex justify-end">
            <button type="button" data-action="signing-stepper#completeCurrentField"
                    class="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium text-sm hover:bg-blue-700 transition-colors cursor-pointer">Apply</button>
          </div>
        </div>
      `
    } else if (type === "email") {
      html = `
        <div class="space-y-4">
          <h3 class="text-sm font-semibold text-gray-900">${field.label || "Email"}</h3>
          <input type="text" class="stepper-text-input block w-full rounded-lg border border-gray-300 text-sm py-2.5 px-3 bg-gray-50"
                 value="${this.escapeHtml(this.signerEmailValue)}"
                 readonly>
          <p class="text-xs text-gray-400">Pre-filled from your signing invitation</p>
          <div class="flex justify-end">
            <button type="button" data-action="signing-stepper#completeCurrentField"
                    class="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium text-sm hover:bg-blue-700 transition-colors cursor-pointer">Apply</button>
          </div>
        </div>
      `
    } else if (type === "date") {
      const dateStr = new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric", hour: "numeric", minute: "2-digit" })
      html = `
        <div class="space-y-4">
          <h3 class="text-sm font-semibold text-gray-900">${field.label || "Date"}</h3>
          <input type="text" class="stepper-text-input block w-full rounded-lg border border-gray-300 text-sm py-2.5 px-3 bg-gray-50"
                 value="${dateStr}" readonly>
          <p class="text-xs text-gray-400">Today's date will be applied automatically</p>
          <div class="flex justify-end">
            <button type="button" data-action="signing-stepper#completeCurrentField"
                    class="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium text-sm hover:bg-blue-700 transition-colors cursor-pointer">Apply Date</button>
          </div>
        </div>
      `
    } else if (type === "checkbox") {
      html = `
        <div class="space-y-4">
          <h3 class="text-sm font-semibold text-gray-900">${field.label || "Checkbox"}</h3>
          <label class="flex items-center space-x-3 cursor-pointer">
            <input type="checkbox" class="stepper-checkbox rounded border-gray-300 text-blue-600 focus:ring-blue-500 h-5 w-5">
            <span class="text-sm text-gray-700">I confirm this checkbox</span>
          </label>
          <div class="flex justify-end">
            <button type="button" data-action="signing-stepper#completeCurrentField"
                    class="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium text-sm hover:bg-blue-700 transition-colors cursor-pointer">Apply</button>
          </div>
        </div>
      `
    } else {
      // company, title, text
      html = `
        <div class="space-y-4">
          <h3 class="text-sm font-semibold text-gray-900">${field.label || field.type.charAt(0).toUpperCase() + field.type.slice(1)}</h3>
          <input type="text" class="stepper-text-input block w-full rounded-lg border border-gray-300 text-sm py-2.5 px-3 focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
                 placeholder="Enter ${field.type}...">
          <div class="flex justify-end">
            <button type="button" data-action="signing-stepper#completeCurrentField"
                    class="px-6 py-2 bg-blue-600 text-white rounded-lg font-medium text-sm hover:bg-blue-700 transition-colors cursor-pointer">Apply</button>
          </div>
        </div>
      `
    }

    this.fieldPanelTarget.innerHTML = html

    // Initialize drawing canvas if signature/initials
    if (type === "signature" || type === "initials") {
      this.drawMode = "draw"
      this.initDrawingCanvas()
    }
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str || ""
    return div.innerHTML
  }

  // Drawing canvas for signature/initials
  initDrawingCanvas() {
    const canvas = this.fieldPanelTarget.querySelector(".stepper-signing-canvas")
    if (!canvas) return
    this.drawingCanvas = canvas

    // Set actual pixel dimensions
    const rect = canvas.getBoundingClientRect()
    canvas.width = rect.width
    canvas.height = rect.height

    const ctx = canvas.getContext("2d")
    // Fill with white first so drawing is visible in dark mode
    ctx.fillStyle = "#ffffff"
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    ctx.strokeStyle = "#1a1a1a"
    ctx.lineWidth = 2.5
    ctx.lineCap = "round"
    ctx.lineJoin = "round"

    this.isDrawing = false

    // Mouse events
    canvas.addEventListener("mousedown", (e) => this.startDraw(e))
    canvas.addEventListener("mousemove", (e) => this.continueDraw(e))
    canvas.addEventListener("mouseup", () => this.endDraw())
    canvas.addEventListener("mouseleave", () => this.endDraw())

    // Touch events
    canvas.addEventListener("touchstart", (e) => { e.preventDefault(); this.startDraw(e.touches[0]) })
    canvas.addEventListener("touchmove", (e) => { e.preventDefault(); this.continueDraw(e.touches[0]) })
    canvas.addEventListener("touchend", () => this.endDraw())
  }

  startDraw(e) {
    if (!this.drawingCanvas || this.drawMode !== "draw") return
    this.isDrawing = true
    const rect = this.drawingCanvas.getBoundingClientRect()
    const ctx = this.drawingCanvas.getContext("2d")
    ctx.beginPath()
    ctx.moveTo(e.clientX - rect.left, e.clientY - rect.top)
  }

  continueDraw(e) {
    if (!this.isDrawing || !this.drawingCanvas) return
    const rect = this.drawingCanvas.getBoundingClientRect()
    const ctx = this.drawingCanvas.getContext("2d")
    ctx.lineTo(e.clientX - rect.left, e.clientY - rect.top)
    ctx.stroke()
  }

  endDraw() {
    this.isDrawing = false
  }

  // Draw a base64 image inside a field box (for drawn signatures/initials)
  drawImageInField(ctx, dataUrl, left, top, w, h) {
    const img = new Image()
    img.onload = () => {
      // Fit image within the field maintaining aspect ratio
      const imgAspect = img.width / img.height
      const boxAspect = w / h
      let drawW, drawH
      if (imgAspect > boxAspect) {
        drawW = w - 4
        drawH = drawW / imgAspect
      } else {
        drawH = h - 4
        drawW = drawH * imgAspect
      }
      const drawX = left + (w - drawW) / 2
      const drawY = top + (h - drawH) / 2
      ctx.drawImage(img, drawX, drawY, drawW, drawH)
    }
    img.src = dataUrl
  }

  clearPad() {
    if (!this.drawingCanvas) return
    const ctx = this.drawingCanvas.getContext("2d")
    // Fill with white (not just clear) so drawing is visible in dark mode
    ctx.fillStyle = "#ffffff"
    ctx.fillRect(0, 0, this.drawingCanvas.width, this.drawingCanvas.height)
  }

  switchToDraw() {
    this.drawMode = "draw"
    const panel = this.fieldPanelTarget
    const drawMode = panel.querySelector(".stepper-draw-mode")
    const typeMode = panel.querySelector(".stepper-type-mode")
    const drawBtn = panel.querySelector(".stepper-draw-btn")
    const typeBtn = panel.querySelector(".stepper-type-btn")
    if (drawMode) drawMode.classList.remove("hidden")
    if (typeMode) typeMode.classList.add("hidden")
    if (drawBtn) { drawBtn.classList.add("bg-blue-600", "text-white"); drawBtn.classList.remove("bg-white", "text-gray-700") }
    if (typeBtn) { typeBtn.classList.add("bg-white", "text-gray-700"); typeBtn.classList.remove("bg-blue-600", "text-white") }
  }

  switchToType() {
    this.drawMode = "type"
    const panel = this.fieldPanelTarget
    const drawMode = panel.querySelector(".stepper-draw-mode")
    const typeMode = panel.querySelector(".stepper-type-mode")
    const drawBtn = panel.querySelector(".stepper-draw-btn")
    const typeBtn = panel.querySelector(".stepper-type-btn")
    if (drawMode) drawMode.classList.add("hidden")
    if (typeMode) typeMode.classList.remove("hidden")
    if (typeBtn) { typeBtn.classList.add("bg-blue-600", "text-white"); typeBtn.classList.remove("bg-white", "text-gray-700") }
    if (drawBtn) { drawBtn.classList.add("bg-white", "text-gray-700"); drawBtn.classList.remove("bg-blue-600", "text-white") }
  }

  // Complete current field
  async completeCurrentField() {
    const field = this.currentField
    if (!field) return

    const type = field.type
    let artifactData = null
    let captureMethod = "typed"
    let artifactType = type

    if (type === "signature" || type === "initials") {
      if (this.drawMode === "draw" && this.drawingCanvas) {
        artifactData = this.drawingCanvas.toDataURL("image/png")
        captureMethod = "drawn"
        if (this.isCanvasBlank(this.drawingCanvas)) {
          alert("Please draw your " + type + " before applying.")
          return
        }
      } else {
        const typedInput = this.fieldPanelTarget.querySelector(".stepper-typed-input")
        artifactData = typedInput ? typedInput.value.trim() : ""
        captureMethod = "typed"
        if (!artifactData) {
          alert("Please type your " + type + " before applying.")
          return
        }
      }
    } else if (type === "checkbox") {
      const checkbox = this.fieldPanelTarget.querySelector(".stepper-checkbox")
      if (!checkbox || !checkbox.checked) {
        alert("Please check the checkbox before applying.")
        return
      }
      artifactData = "\u2713"
    } else if (type === "date") {
      const input = this.fieldPanelTarget.querySelector(".stepper-text-input")
      artifactData = input ? input.value : new Date().toLocaleDateString()
    } else {
      const input = this.fieldPanelTarget.querySelector(".stepper-text-input")
      artifactData = input ? input.value.trim() : ""
      if (!artifactData) {
        alert("Please enter a value before applying.")
        return
      }
    }

    // Disable button during request
    const applyBtn = this.fieldPanelTarget.querySelector('[data-action="signing-stepper#completeCurrentField"]')
    if (applyBtn) { applyBtn.disabled = true; applyBtn.textContent = "Applying..." }

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      if (type === "signature" || type === "initials") {
        // For drawable types: capture artifact first, then complete
        const captureResp = await fetch(this.captureArtifactUrlValue, {
          method: "POST",
          headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken },
          body: JSON.stringify({
            artifact_type: artifactType,
            artifact_data: artifactData,
            capture_method: captureMethod,
            field_id: field.id
          })
        })
        const captureResult = await captureResp.json()
        if (!captureResult.success) {
          throw new Error(captureResult.error || "Failed to capture artifact")
        }
      } else {
        // For text/checkbox/date: complete field directly
        const resp = await fetch(this.completeFieldUrlValue, {
          method: "POST",
          headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken },
          body: JSON.stringify({
            field_id: field.id,
            artifact_data: artifactData,
            artifact_type: artifactType,
            capture_method: captureMethod
          })
        })
        const result = await resp.json()
        if (!result.success) {
          throw new Error(result.error || "Failed to complete field")
        }
      }

      // Mark field completed locally
      field.completed = true
      field.artifact_value = artifactData
      this.updateProgress()
      this.advanceToNextField()
    } catch (error) {
      console.error("Error completing field:", error)
      alert("Failed to complete field. Please try again.")
      if (applyBtn) { applyBtn.disabled = false; applyBtn.textContent = "Apply" }
    }
  }

  isCanvasBlank(canvas) {
    const ctx = canvas.getContext("2d")
    const data = ctx.getImageData(0, 0, canvas.width, canvas.height).data
    for (let i = 3; i < data.length; i += 4) {
      if (data[i] !== 0) return false
    }
    return true
  }

  advanceToNextField() {
    const nextIdx = this.sigFields.findIndex(f => !f.completed)
    if (nextIdx >= 0) {
      this.currentFieldIndex = nextIdx
      const field = this.sigFields[nextIdx]
      if (field.page !== this.currentPage) {
        this.renderPage(field.page)
      } else {
        this.drawFieldOverlays()
      }
      this.showFieldInput(field)
    } else {
      // All fields completed - show review
      this.showReview()
    }
  }

  showReview() {
    if (this.hasFieldPanelTarget) this.fieldPanelTarget.classList.add("hidden")
    if (this.hasReviewPanelTarget) this.reviewPanelTarget.classList.remove("hidden")
    this.currentFieldIndex = -1
    this.drawFieldOverlays()

    if (this.hasReviewListTarget) {
      const typeBadges = {
        signature: { label: "Signature", color: "bg-purple-100 text-purple-800" },
        initials: { label: "Initials", color: "bg-cyan-100 text-cyan-800" },
        date: { label: "Date", color: "bg-amber-100 text-amber-800" },
        name: { label: "Name", color: "bg-green-100 text-green-800" },
        email: { label: "Email", color: "bg-indigo-100 text-indigo-800" },
        company: { label: "Company", color: "bg-teal-100 text-teal-800" },
        title: { label: "Title", color: "bg-pink-100 text-pink-800" },
        text: { label: "Text", color: "bg-blue-100 text-blue-800" },
        checkbox: { label: "Checkbox", color: "bg-gray-100 text-gray-800" }
      }

      this.reviewListTarget.innerHTML = this.sigFields.map((field, index) => {
        const badge = typeBadges[field.type] || typeBadges.text
        const displayValue = field.artifact_value
          ? (field.artifact_value.startsWith("data:image") ? "(drawn)" : this.escapeHtml(field.artifact_value))
          : "-"
        return `
          <div class="flex items-center justify-between py-3 px-4 bg-gray-50 rounded-lg">
            <div class="flex items-center space-x-3">
              <span class="inline-flex items-center justify-center w-6 h-6 rounded-full bg-green-500 text-white text-xs font-bold">
                <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/></svg>
              </span>
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${badge.color}">${badge.label}</span>
              <span class="text-sm text-gray-700">${displayValue}</span>
            </div>
            <button type="button" data-action="signing-stepper#resetField" data-field-index="${index}"
                    class="text-xs text-gray-500 hover:text-red-600 underline cursor-pointer">Reset</button>
          </div>
        `
      }).join("")
    }
  }

  async resetField(event) {
    const index = parseInt(event.currentTarget.dataset.fieldIndex)
    const field = this.sigFields[index]
    if (!field) return

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const resp = await fetch(this.resetFieldUrlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({ field_id: field.id })
      })
      const result = await resp.json()
      if (result.success) {
        field.completed = false
        field.artifact_value = null
        this.currentFieldIndex = index
        this.updateProgress()
        if (this.hasReviewPanelTarget) this.reviewPanelTarget.classList.add("hidden")
        if (field.page !== this.currentPage) {
          this.renderPage(field.page)
        } else {
          this.drawFieldOverlays()
        }
        this.showFieldInput(field)
      }
    } catch (error) {
      console.error("Error resetting field:", error)
      alert("Failed to reset field. Please try again.")
    }
  }

  async finalize() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.textContent = "Submitting..."
    }

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const resp = await fetch(this.finalizeUrlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({})
      })
      const result = await resp.json()
      if (result.success && result.redirect_url) {
        window.location.href = result.redirect_url
      } else if (result.success) {
        window.location.href = this.successUrlValue
      } else {
        throw new Error(result.error || "Failed to finalize")
      }
    } catch (error) {
      console.error("Error finalizing:", error)
      alert("Failed to submit. Please try again.")
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.textContent = "Submit Signed Document"
      }
    }
  }
}
