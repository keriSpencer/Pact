class ContactTag < ApplicationRecord
  belongs_to :contact
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :contact_id }
end
