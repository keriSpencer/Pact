require "test_helper"

class ContactAssignmentTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:contact)
    should belong_to(:user)
  end

  context "validations" do
    should validate_presence_of(:user_id)
  end

  test "sets assigned_at on create" do
    org = create(:organization)
    contact = create(:contact, organization: org)
    user = create(:user, organization: org)
    assignment = ContactAssignment.create!(contact: contact, user: user)

    assert_not_nil assignment.assigned_at
  end

  test "prevents duplicate assignments" do
    org = create(:organization)
    contact = create(:contact, organization: org)
    user = create(:user, organization: org)
    ContactAssignment.create!(contact: contact, user: user)

    duplicate = ContactAssignment.new(contact: contact, user: user)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "is already assigned to this contact"
  end
end
