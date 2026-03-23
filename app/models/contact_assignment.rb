class ContactAssignment < ApplicationRecord
  belongs_to :contact
  belongs_to :user

  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :contact_id, message: "is already assigned to this contact" }

  before_validation :set_assigned_at, on: :create

  private

  def set_assigned_at
    self.assigned_at ||= Time.current
  end
end
