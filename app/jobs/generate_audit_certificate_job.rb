class GenerateAuditCertificateJob < ApplicationJob
  queue_as :default

  def perform(signature_request_id)
    request = SignatureRequest.find(signature_request_id)
    return unless request.signed?

    pdf_data = AuditCertificateService.new(request).generate!
    return unless pdf_data

    # Find the signed version to attach audit certificate as child
    signed_version = request.signed_version || request.document.versions.signed_versions.order(created_at: :desc).first

    version = request.document.versions.create!(
      version_type: "audit_certificate",
      label: "Audit Certificate - #{request.signer_display_name}",
      signature_request: nil,
      parent_version: signed_version
    )

    version.file.attach(
      io: StringIO.new(pdf_data),
      filename: "audit_certificate_#{request.document.name.parameterize}_#{request.id}.pdf",
      content_type: "application/pdf"
    )

    version
  end
end
