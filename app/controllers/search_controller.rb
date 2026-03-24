class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    if @query.present?
      search_term = "%#{@query.downcase}%"

      @contacts = current_organization.contacts
        .where(
          "LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(email) LIKE :q OR LOWER(company) LIKE :q",
          q: search_term
        )
        .limit(20)

      @documents = current_organization.documents
        .active
        .visible_to(current_user)
        .where(
          "LOWER(documents.name) LIKE :q OR LOWER(documents.description) LIKE :q",
          q: search_term
        )
        .limit(20)
    else
      @contacts = Contact.none
      @documents = Document.none
    end
  end

  def suggestions
    query = params[:q].to_s.strip
    if query.present?
      search_term = "%#{query.downcase}%"

      contacts = current_organization.contacts
        .where(
          "LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(email) LIKE :q OR LOWER(company) LIKE :q",
          q: search_term
        )
        .limit(5)
        .map { |c| { type: "contact", id: c.id, label: c.full_name, detail: c.email } }

      documents = current_organization.documents
        .active
        .visible_to(current_user)
        .where(
          "LOWER(documents.name) LIKE :q OR LOWER(documents.description) LIKE :q",
          q: search_term
        )
        .limit(5)
        .map { |d| { type: "document", id: d.id, label: d.name, detail: d.formatted_file_size } }

      render json: { contacts: contacts, documents: documents }
    else
      render json: { contacts: [], documents: [] }
    end
  end
end
