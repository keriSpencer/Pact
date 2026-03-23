class CleanupStaleDraftsJob < ApplicationJob
  queue_as :default

  def perform
    SignatureRequest.stale_drafts.destroy_all
  end
end
