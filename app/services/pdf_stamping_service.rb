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
    draw_text_in_box(canvas, @signature_request.signature_data, x, y, width, height)
  end

  def stamp_multi_field!(doc)
    @signature_request.signature_fields.includes(:completion).each do |field|
      next unless field.completed?
      stamp = field.stamp_data
      next unless stamp

      page_index = (stamp[:page] || 1) - 1
      page = doc.pages[page_index]
      next unless page

      box = page.box(:media)
      page_width = box.width
      page_height = box.height

      x = (stamp[:x].to_f / 100.0) * page_width
      y = (stamp[:y].to_f / 100.0) * page_height
      width = ((stamp[:width] || 25).to_f / 100.0) * page_width
      height = ((stamp[:height] || 8).to_f / 100.0) * page_height

      canvas = page.canvas(type: :overlay)
      draw_text_in_box(canvas, stamp[:data].to_s, x, y, width, height)
    end
  end

  def draw_text_in_box(canvas, text, x, y, width, height)
    font_size = [height * 0.6, 14].min
    canvas.font("Helvetica", size: font_size)
    canvas.fill_color(0, 0, 0.6)

    # Draw a subtle border
    canvas.stroke_color(0.7, 0.7, 0.7)
    canvas.line_width(0.5)
    canvas.rectangle(x, y, width, height)
    canvas.stroke

    # Draw text centered in box
    text_x = x + 4
    text_y = y + (height - font_size) / 2.0 + 2
    canvas.text(text, at: [text_x, text_y])
  end
end
