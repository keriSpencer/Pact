class ContactNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contact

  def create
    @contact_note = @contact.contact_notes.build(contact_note_params)
    @contact_note.user = current_user

    if @contact_note.save
      redirect_to @contact, notice: "Note added."
    else
      redirect_to @contact, alert: "Error adding note: #{@contact_note.errors.full_messages.join(', ')}"
    end
  end

  def edit
    @contact_note = @contact.contact_notes.find(params[:id])
  end

  def update
    @contact_note = @contact.contact_notes.find(params[:id])

    if @contact_note.update(contact_note_params)
      redirect_to @contact, notice: "Note updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact_note = @contact.contact_notes.find(params[:id])
    @contact_note.destroy
    redirect_to @contact, notice: "Note removed."
  end

  def complete_follow_up
    @contact_note = @contact.contact_notes.find(params[:id])
    @contact_note.complete_follow_up!
    redirect_to @contact, notice: "Follow-up completed."
  end

  private

  def set_contact
    @contact = organization_contacts.find(params[:contact_id])
  end

  def contact_note_params
    params.require(:contact_note).permit(:note, :follow_up_date, :contact_type)
  end
end
