require "test_helper"

class ContactTagTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:contact)
    should belong_to(:tag)
  end

  test "prevents duplicate tag on same contact" do
    org = create(:organization)
    contact = create(:contact, organization: org)
    tag = create(:tag, organization: org)
    ContactTag.create!(contact: contact, tag: tag)

    duplicate = ContactTag.new(contact: contact, tag: tag)
    assert_not duplicate.valid?
  end
end
