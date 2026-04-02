class SignedCopyMailer < ApplicationMailer
  def send_copy(document:, signed_version:, recipient_email:, sender:, message: nil)
    @document = document
    @sender = sender
    @message = message

    attachments["#{document.name} - Signed.pdf"] = signed_version.file.download

    mail(
      to: recipient_email,
      subject: "Signed document: #{document.name}"
    )
  end
end
