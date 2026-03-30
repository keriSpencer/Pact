class MultiSignerPdfStampingService
  def initialize(signing_envelope)
    @envelope = signing_envelope
    @document = signing_envelope.document
  end

  def stamp!
    return nil unless @document.pdf? && @document.file.attached?

    pdf_data = @document.file.download
    doc = HexaPDF::Document.new(io: StringIO.new(pdf_data))

    # Stamp all fields from all signed requests
    @envelope.signature_requests.where(status: :signed).includes(signature_fields: { completion: :signature_artifact }).each do |sr|
      sr.signature_fields.each do |field|
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
        x = (stamp[:x].to_f / 100.0) * page_width - width / 2.0
        y = page_height - (stamp[:y].to_f / 100.0) * page_height - height / 2.0

        canvas = page.canvas(type: :overlay)
        data = stamp[:data].to_s

        if data.start_with?("data:image/")
          draw_image_in_box(doc, canvas, data, x, y, width, height)
        elsif field.field_type == "checkbox"
          checkbox_text = stamp[:label].present? ? "X  #{stamp[:label]}" : "X"
          draw_text_in_box(canvas, checkbox_text, x, y, width, height)
        else
          draw_text_in_box(canvas, data, x, y, width, height)
        end
      end
    end

    add_audit_footer!(doc)

    output = StringIO.new
    doc.write(output)
    output.string
  rescue => e
    Rails.logger.error "Multi-signer PDF stamping failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  private

  def draw_text_in_box(canvas, text, x, y, width, height)
    font_size = [height * 0.5, 12].min
    font_size = [font_size, 6].max
    canvas.font("Helvetica", size: font_size)
    canvas.fill_color(0.1, 0.1, 0.4)
    text_x = x + 4
    text_y = y + (height - font_size) / 2.0 + 2
    canvas.text(text, at: [text_x, text_y])
  end

  def draw_image_in_box(doc, canvas, data_uri, x, y, width, height)
    match = data_uri.match(/\Adata:image\/(\w+);base64,(.+)\z/m)
    return unless match

    image_data = Base64.decode64(match[2])
    begin
      image = doc.images.add(StringIO.new(image_data))
      padding = 2
      available_width = width - (padding * 2)
      available_height = height - (padding * 2)
      scale = [available_width / image.width.to_f, available_height / image.height.to_f].min
      draw_width = image.width * scale
      draw_height = image.height * scale
      img_x = x + (width - draw_width) / 2.0
      img_y = y + (height - draw_height) / 2.0
      canvas.image(image, at: [img_x, img_y], width: draw_width, height: draw_height)
    rescue => e
      Rails.logger.error "Failed to embed signature image: #{e.message}"
    end
  end

  def add_audit_footer!(doc)
    last_page = doc.pages[-1]
    return unless last_page

    canvas = last_page.canvas(type: :overlay)
    canvas.font("Helvetica", size: 6)
    canvas.fill_color(0.5, 0.5, 0.5)

    signers = @envelope.signing_roles.in_order.map { |r| "#{r.display_name} (#{r.display_email})" }.join(", ")
    completed_at = @envelope.completed_at&.strftime("%B %d, %Y at %l:%M:%S %p %Z") || "N/A"
    footer = "Signed via Pact | #{@document.name} | #{signers} | #{completed_at}"
    canvas.text(footer, at: [30, 15])
  end
end
