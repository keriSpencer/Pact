class GenerateSignedPdfJob < ApplicationJob
  queue_as :default

  def perform(signature_request_id)
    request = SignatureRequest.find(signature_request_id)
    request.generate_signed_version!
  end
end
