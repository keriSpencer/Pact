class GenerateMultiSignerPdfJob < ApplicationJob
  queue_as :default

  def perform(signing_envelope_id)
    envelope = SigningEnvelope.find(signing_envelope_id)
    return unless envelope.completed?

    stamped_pdf = MultiSignerPdfStampingService.new(envelope).stamp!
    return unless stamped_pdf

    version = envelope.document.versions.create!(
      version_type: "signed",
      label: "Signed by all parties (#{envelope.signing_roles.count} signers)"
    )
    version.file.attach(
      io: StringIO.new(stamped_pdf),
      filename: "signed_#{envelope.document.file.filename}",
      content_type: "application/pdf"
    )
    version
  end
end
