class FolderShareMailer < ApplicationMailer
  def folder_shared(folder_share)
    @folder_share = folder_share
    @folder = folder_share.folder
    @share_url = folder_share.share_url
    @shared_by = folder_share.shared_by

    mail(
      to: folder_share.email,
      subject: "#{@shared_by.full_name} shared a folder with you: #{@folder.name}"
    )
  end
end
