class ContactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contact, only: [:show, :edit, :update, :destroy, :assign, :tag, :untag]
  before_action :load_form_data, only: [:new, :edit, :create, :update]

  def index
    @contacts = organization_contacts.includes(:assigned_users, :tags)

    unless current_user.can_view_all_contacts?
      @contacts = @contacts.joins(:contact_assignments)
                           .where(contact_assignments: { user_id: current_user.id })
                           .distinct
    end

    if params[:tag_id].present?
      @contacts = @contacts.joins(:contact_tags).where(contact_tags: { tag_id: params[:tag_id] })
    end

    @filter_tags = current_organization.tags.ordered

    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @contacts = @contacts.where(
        "LOWER(contacts.first_name) LIKE :term OR LOWER(contacts.last_name) LIKE :term OR " \
        "LOWER(contacts.email) LIKE :term OR LOWER(contacts.company) LIKE :term OR " \
        "LOWER(contacts.first_name || ' ' || contacts.last_name) LIKE :term",
        term: search_term
      )
    end

    @sort_column = %w[name email company created_at].include?(params[:sort]) ? params[:sort] : "created_at"
    @sort_direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"

    @contacts = case @sort_column
    when "name"
      @contacts.order(Arel.sql("LOWER(contacts.first_name) #{@sort_direction}, LOWER(contacts.last_name) #{@sort_direction}"))
    else
      @contacts.order("contacts.#{@sort_column} #{@sort_direction}")
    end
  end

  def search
    query = params[:q].to_s.strip.downcase
    contacts = organization_contacts.where(
      "LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(email) LIKE :q OR LOWER(company) LIKE :q OR LOWER(first_name || ' ' || last_name) LIKE :q",
      q: "%#{query}%"
    ).limit(10)

    render json: contacts.map { |c| {
      id: c.id, email: c.email, name: c.full_name, company: c.company, title: c.title
    }}
  end

  def show
  end

  def new
    @contact = organization_contacts.new
  end

  def create
    @contact = organization_contacts.new(contact_params)

    if @contact.save
      if params[:assigned_user_ids].present?
        params[:assigned_user_ids].each do |user_id|
          @contact.contact_assignments.create(user_id: user_id) if organization_users.exists?(user_id)
        end
      end
      redirect_to @contact, notice: "Contact was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to @contact, notice: "Contact was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to contacts_path, notice: "#{@contact.full_name} was deleted."
  end

  def tag
    tag = current_organization.tags.find(params[:tag_id])
    @contact.tags << tag unless @contact.tags.include?(tag)
    redirect_to @contact, notice: "Tag added."
  end

  def untag
    contact_tag = @contact.contact_tags.find_by(tag_id: params[:tag_id])
    contact_tag&.destroy
    redirect_to @contact, notice: "Tag removed."
  end

  def assign
    user_ids = params[:user_ids] || []

    @contact.contact_assignments.destroy_all
    user_ids.each do |user_id|
      @contact.contact_assignments.create(user_id: user_id) if organization_users.exists?(user_id)
    end

    redirect_to @contact, notice: "Assignments updated."
  end

  private

  def set_contact
    @contact = organization_contacts.find(params[:id])
  end

  def load_form_data
    @available_users = organization_users.order(:first_name, :last_name)
  end

  def contact_params
    params.require(:contact).permit(:first_name, :last_name, :email, :phone, :company, :title, :linkedin_url)
  end
end
