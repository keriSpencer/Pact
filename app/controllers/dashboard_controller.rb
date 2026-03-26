class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @contacts_count = organization_contacts.count
    @recent_contacts = organization_contacts.order(created_at: :desc).limit(5)

    # Document counts
    @documents_count = organization_documents.active.count

    # Signature activity
    @pending_signatures = SignatureRequest.joins(:document)
      .where(documents: { organization_id: current_organization.id })
      .where(status: [:pending, :sent, :viewed])
      .includes(:document)
      .order(created_at: :desc)
      .limit(5)
    @recent_signatures = SignatureRequest.joins(:document)
      .where(documents: { organization_id: current_organization.id })
      .where(status: :signed)
      .includes(:document)
      .order(signed_at: :desc)
      .limit(5)
    @pending_count = SignatureRequest.joins(:document)
      .where(documents: { organization_id: current_organization.id })
      .where(status: [:pending, :sent, :viewed])
      .count

    # Completed signatures count
    @signed_count = SignatureRequest.joins(:document)
      .where(documents: { organization_id: current_organization.id })
      .where(status: :signed)
      .count

    # Follow-up reminders
    @overdue_followups = ContactNote.joins(:contact)
      .where(contacts: { organization_id: current_organization.id })
      .where(follow_up_completed_at: nil)
      .where("follow_up_date < ?", Date.current)
      .includes(:contact, :user)
      .order(:follow_up_date)
      .limit(5)
    @overdue_count = ContactNote.joins(:contact)
      .where(contacts: { organization_id: current_organization.id })
      .where(follow_up_completed_at: nil)
      .where("follow_up_date < ?", Date.current)
      .count
  end
end
