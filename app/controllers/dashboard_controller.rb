class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @contacts_count = organization_contacts.count
    @recent_contacts = organization_contacts.order(created_at: :desc).limit(8)
  end
end
