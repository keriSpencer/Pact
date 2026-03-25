class PdfStampingService
  def initialize(signature_request)
    @signature_request = signature_request
    @document = signature_request.document
  end

  def stamp!
    return nil unless @document.pdf? && @document.file.attached?

    pdf_data = @document.file.download
    doc = HexaPDF::Document.new(io: StringIO.new(pdf_data))

    if @signature_request.uses_multi_field?
      stamp_multi_field!(doc)
    else
      stamp_single_field!(doc)
    end

    add_audit_footer!(doc)

    output = StringIO.new
    doc.write(output)
    output.string
  rescue => e
    Rails.logger.error "PDF stamping failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  private

  def stamp_single_field!(doc)
    return unless @signature_request.signature_data.present?

    page_index = (@signature_request.signature_page || 1) - 1
    page = doc.pages[page_index]
    return unless page

    box = page.box(:media)
    page_width = box.width
    page_height = box.height

    x = ((@signature_request.signature_x || 50) / 100.0) * page_width
    y = ((@signature_request.signature_y || 50) / 100.0) * page_height
    width = ((@signature_request.signature_width || 25) / 100.0) * page_width
    height = ((@signature_request.signature_height || 8) / 100.0) * page_height

    canvas = page.canvas(type: :overlay)

    if @signature_request.signature_data.start_with?("data:image/")
      draw_image_in_box(doc, canvas, @signature_request.signature_data, x, y, width, height)
    else
      draw_text_in_box(canvas, @signature_request.signature_data, x, y, width, height)
    end
  end

  def stamp_multi_field!(doc)
    @signature_request.signature_fields.includes(:completion => :signature_artifact).each do |field|
      next unless field.completed?
      stamp = field.stamp_data
      next unless stamp

      page_index = (stamp[:page] || 1) - 1
      page = doc.pages[page_index]
      next unless page

      box = page.box(:media)
      page_width = box.width
      page_height = box.height

      width = ((stamp[:width] || 25).to_f / 100.0) * page_width
      height = ((stamp[:height] || 8).to_f / 100.0) * page_height
      # Convert from top-left percentage to PDF bottom-left coordinates
      # x/y are center-point percentages from our JS placement
      x = (stamp[:x].to_f / 100.0) * page_width - width / 2.0
      y = page_height - (stamp[:y].to_f / 100.0) * page_height - height / 2.0

      canvas = page.canvas(type: :overlay)
      data = stamp[:data].to_s

      if data.start_with?("data:image/")
        draw_image_in_box(doc, canvas, data, x, y, width, height)
      elsif field.field_type == "date"
        # Include time in date stamp
        completed_at = field.completion&.completed_at
        display_text = completed_at ? completed_at.strftime("%B %d, %Y at %l:%M %p") : data
        draw_text_in_box(canvas, display_text, x, y, width, height)
      elsif field.field_type == "checkbox"
        checkbox_text = stamp[:label].present? ? "X  #{stamp[:label]}" : "X"
        draw_text_in_box(canvas, checkbox_text, x, y, width, height)
      elsif field.text_input_type?
        # name, email, company, title, text - render as plain text
        draw_text_in_box(canvas, data, x, y, width, height)
      else
        draw_text_in_box(canvas, data, x, y, width, height)
      end
    end
  end

  def draw_text_in_box(canvas, text, x, y, width, height)
    font_size = [height * 0.5, 12].min
    font_size = [font_size, 6].max
    canvas.font("Helvetica", size: font_size)
    canvas.fill_color(0.1, 0.1, 0.4)

    # Subtle background
    canvas.save_graphics_state
    canvas.fill_color(0.97, 0.97, 1.0)
    canvas.rectangle(x, y, width, height)
    canvas.fill
    canvas.restore_graphics_state

    # Border
    canvas.stroke_color(0.7, 0.7, 0.85)
    canvas.line_width(0.5)
    canvas.rectangle(x, y, width, height)
    canvas.stroke

    # Text
    canvas.fill_color(0.1, 0.1, 0.4)
    canvas.font("Helvetica", size: font_size)
    text_x = x + 4
    text_y = y + (height - font_size) / 2.0 + 2
    canvas.text(text, at: [text_x, text_y])
  end

  def draw_image_in_box(doc, canvas, data_uri, x, y, width, height)
    # Extract base64 image data
    match = data_uri.match(/\Adata:image\/(\w+);base64,(.+)\z/m)
    return draw_text_in_box(canvas, "[Signature]", x, y, width, height) unless match

    image_data = Base64.decode64(match[2])

    begin
      image = doc.images.add(StringIO.new(image_data))

      # Calculate aspect-fit dimensions with padding
      padding = 2
      available_width = width - (padding * 2)
      available_height = height - (padding * 2)

      img_width = image.width.to_f
      img_height = image.height.to_f

      scale = [available_width / img_width, available_height / img_height].min
      draw_width = img_width * scale
      draw_height = img_height * scale

      # Center the image in the box
      img_x = x + (width - draw_width) / 2.0
      img_y = y + (height - draw_height) / 2.0

      canvas.image(image, at: [img_x, img_y], width: draw_width, height: draw_height)
    rescue => e
      Rails.logger.error "Failed to embed signature image: #{e.message}"
      draw_text_in_box(canvas, "[Signature]", x, y, width, height)
    end
  end

  def add_audit_footer!(doc)
    last_page = doc.pages[-1]
    return unless last_page

    canvas = last_page.canvas(type: :overlay)
    box = last_page.box(:media)

    footer_y = 15
    canvas.font("Helvetica", size: 6)
    canvas.fill_color(0.5, 0.5, 0.5)

    signed_at = @signature_request.signed_at&.strftime("%B %d, %Y at %l:%M:%S %p %Z") || "N/A"
    footer_text = "Signed via Pact | #{@document.name} | Request ##{@signature_request.id} | #{@signature_request.signer_display_name} | #{signed_at}"
    canvas.text(footer_text, at: [30, footer_y])
  end
end
