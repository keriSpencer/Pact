class FolderSharesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_folder
  before_action :check_ownership

  def create
    @share = @folder.folder_shares.build(
      email: params[:email],
      shared_by: current_user,
      permission_level: :view
    )

    if @share.save
      FolderShareMailer.folder_shared(@share).deliver_later
      respond_to do |format|
        format.html { redirect_to @folder, notice: "Folder shared with #{@share.email}." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @folder, alert: @share.errors.full_messages.first }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("share_form_errors", partial: "folder_shares/form_error", locals: { message: @share.errors.full_messages.first }) }
      end
    end
  end

  def destroy
    @share = @folder.folder_shares.find(params[:id])
    @share.destroy!

    respond_to do |format|
      format.html { redirect_to @folder, notice: "Share removed." }
      format.turbo_stream
    end
  end

  private

  def set_folder
    @folder = Folder.find(params[:folder_id])
  end

  def check_ownership
    unless @folder.user == current_user || current_user.admin?
      flash[:alert] = "Only the folder owner can manage sharing."
      redirect_to @folder
    end
  end
end
