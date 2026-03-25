class SignatureRequestMailer < ApplicationMailer
  def signature_request(signature_request)
    @signature_request = signature_request
    @document = signature_request.document
    @signing_url = signature_request.signature_url

    mail(
      to: signature_request.signer_email,
      subject: "Signature requested: #{@document.name}"
    )
  end

  def signature_completed(signature_request)
    @signature_request = signature_request
    @document = signature_request.document

    mail(
      to: signature_request.requester.email,
      subject: "Document signed: #{@document.name}"
    )
  end

  def signer_copy(signature_request)
    @signature_request = signature_request
    @document = signature_request.document
    @view_url = signature_request.signed_view_url

    mail(
      to: signature_request.signer_email,
      subject: "Your signed copy: #{@document.name}"
    )
  end

  def signature_declined(signature_request)
    @signature_request = signature_request
    @document = signature_request.document

    mail(
      to: signature_request.requester.email,
      subject: "Signature declined: #{@document.name}"
    )
  end

  def signature_reminder(signature_request)
    @signature_request = signature_request
    @document = signature_request.document
    @signing_url = signature_request.signature_url

    mail(
      to: signature_request.signer_email,
      subject: "Reminder: Signature requested for #{@document.name}"
    )
  end
end
