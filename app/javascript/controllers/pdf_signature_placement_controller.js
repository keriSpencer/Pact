import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "canvas", "pageIndicator", "fieldsInput", "loadingState",
    "canvasContainer", "fieldsList", "fieldCount", "addFieldType",
    "labelInput", "fieldLabel", "fieldTypePill"
  ]
  static values = {
    pdfUrl: String,
    currentPage: { type: Number, default: 1 },
    totalPages: { type: Number, default: 1 }
  }

  get fieldDefaults() {
    return {
      signature: { width: 25.0, height: 8.0 },
      initials:  { width: 12.0, height: 6.0 },
      date:      { width: 20.0, height: 5.0 },
      text:      { width: 30.0, height: 5.0 },
      name:      { width: 25.0, height: 5.0 },
      email:     { width: 25.0, height: 5.0 },
      company:   { width: 25.0, height: 5.0 },
      title:     { width: 20.0, height: 5.0 },
      checkbox:  { width: 4.0, height: 4.0 }
    }
  }

  get MIN_WIDTH_PX()  { return 80 }
  get MIN_HEIGHT_PX() { return 28 }
  get MAX_WIDTH_PCT() { return 100 }
  get MAX_HEIGHT_PCT(){ return 30 }
  get HANDLE_SIZE()   { return 8 }
  get DRAG_THRESHOLD(){ return 5 }

  connect() {
    this.signatureFields = []
    this.pdfDoc = null
    this.nextFieldId = 1
    this.selectedFieldId = null
    this.pdfCanvasImage = null
    this.dragState = null
    this.dragStarted = false
    this.mouseDownPos = null

    this._onMouseMove = this.onDocumentMouseMove.bind(this)
    this._onMouseUp = this.onDocumentMouseUp.bind(this)

    this.restoreFields()
    this.loadPdf()
  }

  restoreFields() {
    if (!this.hasFieldsInputTarget) return
    const fieldsJson = this.fieldsInputTarget.value
    if (!fieldsJson || fieldsJson === '[]') return
    try {
      const fieldsData = JSON.parse(fieldsJson)
      this.signatureFields = fieldsData.map((data, index) => ({
        id: this.nextFieldId++,
        x: parseFloat(data.x_percent),
        y: parseFloat(data.y_percent),
        page: parseInt(data.page_number) || 1,
        width: parseFloat(data.width_percent),
        height: parseFloat(data.height_percent),
        type: data.field_type || 'signature',
        label: data.label || null,
        required: data.required !== false,
        position: data.position || (index + 1)
      }))
      this.updateFieldsList()
    } catch (e) {
      console.error("Failed to restore fields:", e)
    }
  }

  disconnect() {
    document.removeEventListener('mousemove', this._onMouseMove)
    document.removeEventListener('mouseup', this._onMouseUp)
  }

  async loadPdf() {
    try {
      this.showLoading()
      const pdfjsLib = await import("pdfjs-dist")
      pdfjsLib.GlobalWorkerOptions.workerSrc = "https://cdn.jsdelivr.net/npm/pdfjs-dist@4.0.379/build/pdf.worker.min.mjs"
      const loadingTask = pdfjsLib.getDocument(this.pdfUrlValue)
      this.pdfDoc = await loadingTask.promise
      this.totalPagesValue = this.pdfDoc.numPages
      await this.renderPage(1)
      this.hideLoading()
    } catch (error) {
      console.error("Error loading PDF:", error)
      this.showError("Failed to load PDF preview")
    }
  }

  async renderPage(pageNum) {
    if (!this.pdfDoc) return
    const page = await this.pdfDoc.getPage(pageNum)
    const scale = this.calculateScale(page)
    const viewport = page.getViewport({ scale })
    const canvas = this.canvasTarget
    const context = canvas.getContext("2d")
    canvas.height = viewport.height
    canvas.width = viewport.width
    await page.render({ canvasContext: context, viewport }).promise
    this.currentPageValue = pageNum
    this.updatePageIndicator()
    this.pdfCanvasImage = context.getImageData(0, 0, canvas.width, canvas.height)
    this.drawFieldsOnCurrentPage()
  }

  redrawFields() {
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    if (this.pdfCanvasImage) ctx.putImageData(this.pdfCanvasImage, 0, 0)
    this.drawFieldsOnCurrentPage()
  }

  calculateScale(page) {
    const viewport = page.getViewport({ scale: 1 })
    const containerWidth = Math.max(this.canvasContainerTarget.clientWidth - 20, 500)
    let scale = containerWidth / viewport.width
    if (viewport.height * scale > 700) scale = 700 / viewport.height
    return Math.min(scale, 1.5)
  }

  // Canvas events
  handleCanvasMouseDown(event) {
    event.preventDefault()
    const canvas = this.canvasTarget
    const rect = canvas.getBoundingClientRect()
    const mouseX = event.clientX - rect.left
    const mouseY = event.clientY - rect.top
    const xPct = (mouseX / rect.width) * 100
    const yPct = (mouseY / rect.height) * 100
    this.mouseDownPos = { x: mouseX, y: mouseY, xPct, yPct }
    this.dragStarted = false

    if (this.selectedFieldId !== null) {
      const handle = this.hitTestHandles(mouseX, mouseY, canvas)
      if (handle) { this.startResize(handle, canvas); return }
    }

    const clickedField = this.hitTestField(xPct, yPct)
    if (clickedField) {
      this.selectedFieldId = clickedField.id
      this.dragState = { mode: 'moving', fieldId: clickedField.id, offsetXPct: xPct - clickedField.x, offsetYPct: yPct - clickedField.y }
      canvas.style.cursor = 'grabbing'
      this.redrawFields()
      this.updateFieldsList()
      document.addEventListener('mousemove', this._onMouseMove)
      document.addEventListener('mouseup', this._onMouseUp)
      return
    }

    const hadSelection = this.selectedFieldId !== null
    this.selectedFieldId = null
    this.dragState = { mode: 'creating', startXPct: xPct, startYPct: yPct, deselecting: hadSelection }
    this.redrawFields()
    this.updateFieldsList()
    document.addEventListener('mousemove', this._onMouseMove)
    document.addEventListener('mouseup', this._onMouseUp)
  }

  handleCanvasHover(event) {
    if (this.dragState) return
    const canvas = this.canvasTarget
    const rect = canvas.getBoundingClientRect()
    const mouseX = event.clientX - rect.left
    const mouseY = event.clientY - rect.top
    const xPct = (mouseX / rect.width) * 100
    const yPct = (mouseY / rect.height) * 100

    if (this.selectedFieldId !== null) {
      const handle = this.hitTestHandles(mouseX, mouseY, canvas)
      if (handle) { canvas.style.cursor = this.handleCursor(handle.name); return }
    }
    canvas.style.cursor = this.hitTestField(xPct, yPct) ? 'grab' : 'crosshair'
  }

  handleCursor(name) {
    return (name === 'top-left' || name === 'bottom-right') ? 'nwse-resize' : 'nesw-resize'
  }

  onDocumentMouseMove(event) {
    if (!this.dragState || !this.mouseDownPos) return
    const canvas = this.canvasTarget
    const rect = canvas.getBoundingClientRect()
    const mouseX = event.clientX - rect.left
    const mouseY = event.clientY - rect.top

    if (!this.dragStarted) {
      const dx = mouseX - this.mouseDownPos.x
      const dy = mouseY - this.mouseDownPos.y
      if (Math.sqrt(dx * dx + dy * dy) < this.DRAG_THRESHOLD) return
      this.dragStarted = true
    }

    const xPct = (mouseX / rect.width) * 100
    const yPct = (mouseY / rect.height) * 100

    if (this.dragState.mode === 'resizing') this.performResize(mouseX, mouseY, canvas)
    else if (this.dragState.mode === 'moving') this.performMove(xPct, yPct)
    else if (this.dragState.mode === 'creating') this.drawCreatePreview(xPct, yPct)
  }

  onDocumentMouseUp() {
    document.removeEventListener('mousemove', this._onMouseMove)
    document.removeEventListener('mouseup', this._onMouseUp)
    if (!this.dragState) { this.mouseDownPos = null; return }

    const mode = this.dragState.mode
    if (mode === 'resizing') {
      this.updateFormData(); this.updateFieldsList()
    } else if (mode === 'moving') {
      if (this.dragStarted) { this.updateFormData(); this.updateFieldsList() }
    } else if (mode === 'creating') {
      if (this.dragStarted) this.createFieldFromDrag()
      else if (!this.dragState.deselecting) this.placeNewField(this.mouseDownPos.xPct, this.mouseDownPos.yPct)
    }

    this.dragState = null
    this.mouseDownPos = null
    this.dragStarted = false
    this.canvasTarget.style.cursor = 'crosshair'
  }

  handleKeyDown(event) {
    const tag = event.target.tagName
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return
    if (this.selectedFieldId === null) return
    if (event.key === 'Delete' || event.key === 'Backspace') {
      event.preventDefault(); this.deleteSelectedField()
    } else if (event.key === 'Escape') {
      this.selectedFieldId = null; this.redrawFields(); this.updateFieldsList()
    }
  }

  deleteSelectedField() {
    if (this.selectedFieldId === null) return
    this.signatureFields = this.signatureFields.filter(f => f.id !== this.selectedFieldId)
    this.selectedFieldId = null
    this.signatureFields.forEach((f, i) => f.position = i + 1)
    this.updateFormData(); this.redrawFields(); this.updateFieldsList()
  }

  // Hit testing
  hitTestHandles(mouseX, mouseY, canvas) {
    if (this.selectedFieldId === null) return null
    const field = this.signatureFields.find(f => f.id === this.selectedFieldId)
    if (!field || field.page !== this.currentPageValue) return null
    const handles = this.getHandlePositions(field, canvas)
    for (const [name, pos] of Object.entries(handles)) {
      if (Math.abs(mouseX - pos.x) <= this.HANDLE_SIZE + 2 && Math.abs(mouseY - pos.y) <= this.HANDLE_SIZE + 2)
        return { name, field }
    }
    return null
  }

  hitTestField(xPct, yPct) {
    for (let i = this.signatureFields.length - 1; i >= 0; i--) {
      const f = this.signatureFields[i]
      if (f.page !== this.currentPageValue) continue
      if (xPct >= f.x - f.width/2 && xPct <= f.x + f.width/2 && yPct >= f.y - f.height/2 && yPct <= f.y + f.height/2)
        return f
    }
    return null
  }

  getHandlePositions(field, canvas) {
    const x = (field.x / 100) * canvas.width, y = (field.y / 100) * canvas.height
    const w = (field.width / 100) * canvas.width, h = (field.height / 100) * canvas.height
    return {
      'top-left': { x: x - w/2, y: y - h/2 }, 'top-right': { x: x + w/2, y: y - h/2 },
      'bottom-left': { x: x - w/2, y: y + h/2 }, 'bottom-right': { x: x + w/2, y: y + h/2 }
    }
  }

  // Resize
  startResize(handle, canvas) {
    const field = handle.field
    const x = (field.x / 100) * canvas.width, y = (field.y / 100) * canvas.height
    const w = (field.width / 100) * canvas.width, h = (field.height / 100) * canvas.height
    let anchorX, anchorY
    switch (handle.name) {
      case 'top-left': anchorX = x + w/2; anchorY = y + h/2; break
      case 'top-right': anchorX = x - w/2; anchorY = y + h/2; break
      case 'bottom-left': anchorX = x + w/2; anchorY = y - h/2; break
      case 'bottom-right': anchorX = x - w/2; anchorY = y - h/2; break
    }
    this.dragState = { mode: 'resizing', fieldId: field.id, anchorX, anchorY }
    this.dragStarted = true
    this.canvasTarget.style.cursor = this.handleCursor(handle.name)
    document.addEventListener('mousemove', this._onMouseMove)
    document.addEventListener('mouseup', this._onMouseUp)
  }

  performResize(mouseX, mouseY, canvas) {
    const field = this.signatureFields.find(f => f.id === this.dragState.fieldId)
    if (!field) return
    const { anchorX, anchorY } = this.dragState
    let left = Math.min(anchorX, mouseX), right = Math.max(anchorX, mouseX)
    let top = Math.min(anchorY, mouseY), bottom = Math.max(anchorY, mouseY)
    if (right - left < this.MIN_WIDTH_PX) { if (mouseX < anchorX) left = anchorX - this.MIN_WIDTH_PX; else right = anchorX + this.MIN_WIDTH_PX }
    if (bottom - top < this.MIN_HEIGHT_PX) { if (mouseY < anchorY) top = anchorY - this.MIN_HEIGHT_PX; else bottom = anchorY + this.MIN_HEIGHT_PX }
    let wPct = Math.min(((right - left) / canvas.width) * 100, this.MAX_WIDTH_PCT)
    let hPct = Math.min(((bottom - top) / canvas.height) * 100, this.MAX_HEIGHT_PCT)
    let cxPct = Math.max(wPct/2, Math.min(100 - wPct/2, ((left + right) / 2 / canvas.width) * 100))
    let cyPct = Math.max(hPct/2, Math.min(100 - hPct/2, ((top + bottom) / 2 / canvas.height) * 100))
    field.x = parseFloat(cxPct.toFixed(2)); field.y = parseFloat(cyPct.toFixed(2))
    field.width = parseFloat(wPct.toFixed(2)); field.height = parseFloat(hPct.toFixed(2))
    this.redrawFields()
  }

  performMove(xPct, yPct) {
    const field = this.signatureFields.find(f => f.id === this.dragState.fieldId)
    if (!field) return
    let newX = xPct - this.dragState.offsetXPct, newY = yPct - this.dragState.offsetYPct
    field.x = parseFloat(Math.max(field.width/2, Math.min(100 - field.width/2, newX)).toFixed(2))
    field.y = parseFloat(Math.max(field.height/2, Math.min(100 - field.height/2, newY)).toFixed(2))
    this.redrawFields()
  }

  // Create
  drawCreatePreview(xPct, yPct) {
    this.lastDragXPct = xPct; this.lastDragYPct = yPct
    this.redrawFields()
    const { startXPct, startYPct } = this.dragState
    const canvas = this.canvasTarget, ctx = canvas.getContext("2d")
    const fieldType = this.hasAddFieldTypeTarget ? this.addFieldTypeTarget.value : 'signature'
    const colors = this.fieldColor(fieldType)
    const x1 = (Math.min(startXPct, xPct) / 100) * canvas.width
    const y1 = (Math.min(startYPct, yPct) / 100) * canvas.height
    const w = (Math.abs(xPct - startXPct) / 100) * canvas.width
    const h = (Math.abs(yPct - startYPct) / 100) * canvas.height
    ctx.strokeStyle = colors.solid; ctx.lineWidth = 2; ctx.setLineDash([6, 4])
    ctx.strokeRect(x1, y1, w, h); ctx.fillStyle = colors.fill; ctx.fillRect(x1, y1, w, h); ctx.setLineDash([])
  }

  createFieldFromDrag() {
    const { startXPct, startYPct } = this.dragState
    const canvas = this.canvasTarget
    const endXPct = this.lastDragXPct || startXPct, endYPct = this.lastDragYPct || startYPct
    let wPct = Math.max(Math.abs(endXPct - startXPct), (this.MIN_WIDTH_PX / canvas.width) * 100)
    let hPct = Math.max(Math.abs(endYPct - startYPct), (this.MIN_HEIGHT_PX / canvas.height) * 100)
    wPct = Math.min(wPct, this.MAX_WIDTH_PCT); hPct = Math.min(hPct, this.MAX_HEIGHT_PCT)
    let cx = Math.max(wPct/2, Math.min(100 - wPct/2, Math.min(startXPct, endXPct) + wPct/2))
    let cy = Math.max(hPct/2, Math.min(100 - hPct/2, Math.min(startYPct, endYPct) + hPct/2))
    const fieldType = this.hasAddFieldTypeTarget ? this.addFieldTypeTarget.value : 'signature'
    const newField = {
      id: this.nextFieldId++, x: parseFloat(cx.toFixed(2)), y: parseFloat(cy.toFixed(2)),
      page: this.currentPageValue, width: parseFloat(wPct.toFixed(2)), height: parseFloat(hPct.toFixed(2)),
      type: fieldType, label: null, required: true, position: this.signatureFields.length + 1
    }
    this.signatureFields.push(newField)
    this.selectedFieldId = newField.id
    this.updateFormData(); this.redrawFields(); this.updateFieldsList()
    this.element.focus()
  }

  placeNewField(xPct, yPct) {
    const fieldType = this.hasAddFieldTypeTarget ? this.addFieldTypeTarget.value : 'signature'
    const defaults = this.fieldDefaults[fieldType] || this.fieldDefaults.signature
    const newField = {
      id: this.nextFieldId++, x: Math.max(5, Math.min(95, xPct)), y: Math.max(5, Math.min(95, yPct)),
      page: this.currentPageValue, width: defaults.width, height: defaults.height,
      type: fieldType, label: null, required: true, position: this.signatureFields.length + 1
    }
    this.signatureFields.push(newField)
    this.selectedFieldId = newField.id
    this.updateFormData(); this.redrawFields(); this.updateFieldsList()
    this.element.focus()
  }

  // Drawing
  drawFieldsOnCurrentPage() {
    const canvas = this.canvasTarget, ctx = canvas.getContext("2d")
    this.signatureFields.forEach((field, index) => {
      if (field.page === this.currentPageValue) this.drawFieldMarker(ctx, canvas, field, index + 1, field.id === this.selectedFieldId)
    })
  }

  fieldColor(type) {
    switch (type) {
      case 'signature': return { solid: '#7c3aed', fill: 'rgba(124,58,237,0.1)', selectedFill: 'rgba(124,58,237,0.2)' }
      case 'initials': return { solid: '#0891b2', fill: 'rgba(8,145,178,0.1)', selectedFill: 'rgba(8,145,178,0.2)' }
      case 'date': return { solid: '#d97706', fill: 'rgba(217,119,6,0.1)', selectedFill: 'rgba(217,119,6,0.2)' }
      case 'text': return { solid: '#2563eb', fill: 'rgba(37,99,235,0.1)', selectedFill: 'rgba(37,99,235,0.2)' }
      case 'name': return { solid: '#16a34a', fill: 'rgba(22,163,74,0.1)', selectedFill: 'rgba(22,163,74,0.2)' }
      case 'email': return { solid: '#4f46e5', fill: 'rgba(79,70,229,0.1)', selectedFill: 'rgba(79,70,229,0.2)' }
      case 'company': return { solid: '#0d9488', fill: 'rgba(13,148,136,0.1)', selectedFill: 'rgba(13,148,136,0.2)' }
      case 'title': return { solid: '#ec4899', fill: 'rgba(236,72,153,0.1)', selectedFill: 'rgba(236,72,153,0.2)' }
      case 'checkbox': return { solid: '#6b7280', fill: 'rgba(107,114,128,0.1)', selectedFill: 'rgba(107,114,128,0.2)' }
      default: return { solid: '#7c3aed', fill: 'rgba(124,58,237,0.1)', selectedFill: 'rgba(124,58,237,0.2)' }
    }
  }

  fieldDefaultLabel(field) {
    if (field.label) return field.label
    switch (field.type) {
      case 'signature': return 'Sign Here'
      case 'initials': return 'Initial Here'
      case 'date': return 'Date'
      case 'name': return 'Print Name'
      case 'email': return 'Email'
      case 'company': return 'Company'
      case 'title': return 'Title'
      case 'checkbox': return '\u2610'
      default: return 'Text'
    }
  }

  drawFieldMarker(ctx, canvas, field, number, isSelected) {
    const x = (field.x / 100) * canvas.width, y = (field.y / 100) * canvas.height
    const w = (field.width / 100) * canvas.width, h = (field.height / 100) * canvas.height
    const colors = this.fieldColor(field.type)
    ctx.strokeStyle = colors.solid; ctx.lineWidth = isSelected ? 3 : 2
    ctx.setLineDash(isSelected ? [] : [5, 5])
    ctx.strokeRect(x - w/2, y - h/2, w, h)
    ctx.fillStyle = isSelected ? colors.selectedFill : colors.fill
    ctx.fillRect(x - w/2, y - h/2, w, h)
    ctx.setLineDash([])
    // Number badge
    ctx.fillStyle = colors.solid; ctx.beginPath(); ctx.arc(x - w/2 + 12, y - h/2 + 12, 12, 0, 2 * Math.PI); ctx.fill()
    ctx.fillStyle = '#fff'; ctx.font = 'bold 12px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'
    ctx.fillText(number.toString(), x - w/2 + 12, y - h/2 + 12)
    // Label
    ctx.fillStyle = colors.solid; ctx.font = 'bold 14px sans-serif'
    ctx.fillText(this.fieldDefaultLabel(field), x, y)
    if (isSelected) this.drawResizeHandles(ctx, canvas, field, colors)
  }

  drawResizeHandles(ctx, canvas, field, colors) {
    const handles = this.getHandlePositions(field, canvas)
    for (const pos of Object.values(handles)) {
      ctx.fillStyle = '#fff'; ctx.strokeStyle = colors.solid; ctx.lineWidth = 2
      ctx.fillRect(pos.x - this.HANDLE_SIZE/2, pos.y - this.HANDLE_SIZE/2, this.HANDLE_SIZE, this.HANDLE_SIZE)
      ctx.strokeRect(pos.x - this.HANDLE_SIZE/2, pos.y - this.HANDLE_SIZE/2, this.HANDLE_SIZE, this.HANDLE_SIZE)
    }
  }

  // Field management
  removeField(event) {
    event.stopPropagation()
    const fieldId = parseInt(event.currentTarget.dataset.fieldId)
    if (this.selectedFieldId === fieldId) this.selectedFieldId = null
    this.signatureFields = this.signatureFields.filter(f => f.id !== fieldId)
    this.signatureFields.forEach((f, i) => f.position = i + 1)
    this.updateFormData(); this.redrawFields(); this.updateFieldsList()
  }

  selectField(event) {
    const fieldId = parseInt(event.currentTarget.dataset.fieldId)
    const field = this.signatureFields.find(f => f.id === fieldId)
    if (!field) return
    this.selectedFieldId = fieldId
    if (field.page !== this.currentPageValue) this.renderPage(field.page)
    else this.redrawFields()
    this.updateFieldsList()
    this.element.focus()
  }

  clearAllFields() {
    this.signatureFields = []; this.nextFieldId = 1; this.selectedFieldId = null
    this.updateFormData(); this.redrawFields(); this.updateFieldsList()
  }

  updateFieldsList() {
    if (!this.hasFieldsListTarget) return
    if (this.signatureFields.length === 0) {
      this.fieldsListTarget.innerHTML = '<p class="text-sm text-gray-500 py-4 text-center">Click or drag on the document to place fields</p>'
    } else {
      const typeConfig = {
        signature: { label: 'Signature', color: 'bg-purple-100 text-purple-800', badge: 'bg-purple-600' },
        initials: { label: 'Initials', color: 'bg-cyan-100 text-cyan-800', badge: 'bg-cyan-600' },
        date: { label: 'Date Signed', color: 'bg-amber-100 text-amber-800', badge: 'bg-amber-600' },
        text: { label: 'Text', color: 'bg-blue-100 text-blue-800', badge: 'bg-blue-600' },
        name: { label: 'Name', color: 'bg-green-100 text-green-800', badge: 'bg-green-600' },
        email: { label: 'Email', color: 'bg-indigo-100 text-indigo-800', badge: 'bg-indigo-600' },
        company: { label: 'Company', color: 'bg-teal-100 text-teal-800', badge: 'bg-teal-600' },
        title: { label: 'Title', color: 'bg-pink-100 text-pink-800', badge: 'bg-pink-600' },
        checkbox: { label: 'Checkbox', color: 'bg-gray-100 text-gray-800', badge: 'bg-gray-600' }
      }
      this.fieldsListTarget.innerHTML = this.signatureFields.map((field, index) => {
        const cfg = typeConfig[field.type] || typeConfig.signature
        const sel = field.id === this.selectedFieldId ? 'ring-2 ring-purple-400 bg-purple-50' : 'bg-gray-50'
        return `<div class="flex items-center justify-between py-2 px-3 ${sel} rounded-lg cursor-pointer" data-action="click->pdf-signature-placement#selectField" data-field-id="${field.id}">
          <div class="flex items-center space-x-3">
            <span class="flex items-center justify-center h-6 w-6 rounded-full ${cfg.badge} text-white text-xs font-bold">${index + 1}</span>
            <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${cfg.color}">${cfg.label}</span>
            <span class="text-xs text-gray-500">Page ${field.page}</span>
          </div>
          <button type="button" data-action="click->pdf-signature-placement#removeField" data-field-id="${field.id}" class="text-xs text-red-600 hover:text-red-800">Remove</button>
        </div>`
      }).join('')
    }
    if (this.hasFieldCountTarget) {
      const c = this.signatureFields.length
      this.fieldCountTarget.textContent = `${c} field${c !== 1 ? 's' : ''} placed`
    }
  }

  updateFormData() {
    if (!this.hasFieldsInputTarget) return
    this.fieldsInputTarget.value = JSON.stringify(this.signatureFields.map(f => ({
      page_number: f.page, x_percent: f.x.toFixed(2), y_percent: f.y.toFixed(2),
      width_percent: f.width.toFixed(2), height_percent: f.height.toFixed(2),
      field_type: f.type, required: f.required, position: f.position, label: f.label || null
    })))
  }

  // Page navigation
  nextPage() { if (this.currentPageValue < this.totalPagesValue) this.renderPage(this.currentPageValue + 1) }
  previousPage() { if (this.currentPageValue > 1) this.renderPage(this.currentPageValue - 1) }
  updatePageIndicator() { if (this.hasPageIndicatorTarget) this.pageIndicatorTarget.textContent = `Page ${this.currentPageValue} of ${this.totalPagesValue}` }

  // Field type selection via pills
  selectFieldType(event) {
    const type = event.currentTarget.dataset.fieldType
    if (!type) return

    // Update hidden select
    if (this.hasAddFieldTypeTarget) this.addFieldTypeTarget.value = type

    // Color map for each type
    const colors = {
      signature: 'bg-purple-100 text-purple-800 border-purple-300',
      initials: 'bg-cyan-100 text-cyan-800 border-cyan-300',
      name: 'bg-green-100 text-green-800 border-green-300',
      date: 'bg-amber-100 text-amber-800 border-amber-300',
      text: 'bg-blue-100 text-blue-800 border-blue-300',
      checkbox: 'bg-gray-100 text-gray-800 border-gray-300',
      email: 'bg-indigo-100 text-indigo-800 border-indigo-300',
      company: 'bg-teal-100 text-teal-800 border-teal-300',
      title: 'bg-pink-100 text-pink-800 border-pink-300'
    }

    const inactive = 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'

    // Reset all pills to inactive
    this.fieldTypePillTargets.forEach(pill => {
      pill.className = `px-3 py-1.5 text-xs font-medium rounded-full border transition-colors cursor-pointer ${inactive}`
    })

    // Activate the clicked pill
    const activeColors = colors[type] || colors.text
    event.currentTarget.className = `px-3 py-1.5 text-xs font-medium rounded-full border transition-colors cursor-pointer ${activeColors}`
  }

  // Loading states
  showLoading() {
    if (this.hasLoadingStateTarget) this.loadingStateTarget.classList.remove("hidden")
    if (this.hasCanvasTarget) this.canvasTarget.style.opacity = "0"
  }
  hideLoading() {
    if (this.hasLoadingStateTarget) this.loadingStateTarget.classList.add("hidden")
    if (this.hasCanvasContainerTarget) this.canvasContainerTarget.classList.remove("hidden")
    if (this.hasCanvasTarget) this.canvasTarget.style.opacity = "1"
  }
  showError(message) {
    this.hideLoading()
    if (this.hasLoadingStateTarget) {
      this.loadingStateTarget.innerHTML = `<div class="text-center text-red-600 py-8"><p>${message}</p></div>`
      this.loadingStateTarget.classList.remove("hidden")
    }
  }
}
