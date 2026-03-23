require "test_helper"

class ContactTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:organization)
    should have_many(:contact_assignments).dependent(:destroy)
    should have_many(:assigned_users).through(:contact_assignments)
  end

  context "validations" do
    should validate_presence_of(:first_name)
    should validate_presence_of(:email)
  end

  test "full_name returns first and last name" do
    contact = build(:contact, first_name: "Jane", last_name: "Doe")
    assert_equal "Jane Doe", contact.full_name
  end

  test "full_name with only first name" do
    contact = build(:contact, first_name: "Jane", last_name: nil)
    assert_equal "Jane", contact.full_name
  end

  test "name aliases full_name" do
    contact = build(:contact, first_name: "Jane", last_name: "Doe")
    assert_equal contact.full_name, contact.name
  end

  test "email uniqueness scoped to organization" do
    org = create(:organization)
    create(:contact, email: "test@example.com", organization: org)
    duplicate = build(:contact, email: "test@example.com", organization: org)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "email uniqueness allows same email in different orgs" do
    org1 = create(:organization)
    org2 = create(:organization)
    create(:contact, email: "test@example.com", organization: org1)
    contact2 = build(:contact, email: "test@example.com", organization: org2)

    assert contact2.valid?
  end

  test "email validation rejects invalid format" do
    contact = build(:contact, email: "not-an-email")
    assert_not contact.valid?
  end

  test "linkedin_url validation accepts valid URLs" do
    contact = build(:contact, linkedin_url: "https://linkedin.com/in/johndoe")
    assert contact.valid?
  end

  test "linkedin_url validation rejects non-LinkedIn URLs" do
    contact = build(:contact, linkedin_url: "https://example.com/profile")
    assert_not contact.valid?
  end

  test "linkedin_url allows blank" do
    contact = build(:contact, linkedin_url: "")
    assert contact.valid?
  end

  test "linkedin_display returns slug" do
    contact = build(:contact, linkedin_url: "https://www.linkedin.com/in/johndoe")
    assert_equal "/in/johndoe", contact.linkedin_display
  end

  test "linkedin_display returns nil when blank" do
    contact = build(:contact, linkedin_url: nil)
    assert_nil contact.linkedin_display
  end

  test "soft delete sets deleted_at" do
    contact = create(:contact)
    contact.destroy
    assert contact.deleted?
    assert_not_nil contact.deleted_at
  end

  test "default scope excludes deleted contacts" do
    org = create(:organization)
    active = create(:contact, organization: org)
    deleted = create(:contact, organization: org)
    deleted.destroy

    assert_includes Contact.all, active
    assert_not_includes Contact.all, deleted
  end

  test "with_deleted scope includes deleted contacts" do
    contact = create(:contact)
    contact.destroy

    assert_includes Contact.with_deleted, contact
  end

  test "restore! clears deleted_at" do
    contact = create(:contact)
    contact.destroy
    contact.restore!

    assert_not contact.deleted?
  end

  test "unassigned scope returns contacts without assignments" do
    org = create(:organization)
    assigned = create(:contact, organization: org)
    unassigned = create(:contact, organization: org)
    user = create(:user, organization: org)
    create(:contact_assignment, contact: assigned, user: user)

    result = org.contacts.unassigned
    assert_includes result, unassigned
    assert_not_includes result, assigned
  end

  test "assigned scope returns contacts with assignments" do
    org = create(:organization)
    assigned = create(:contact, organization: org)
    unassigned = create(:contact, organization: org)
    user = create(:user, organization: org)
    create(:contact_assignment, contact: assigned, user: user)

    result = org.contacts.assigned
    assert_includes result, assigned
    assert_not_includes result, unassigned
  end

  test "unassigned? returns true when no users assigned" do
    contact = create(:contact)
    assert contact.unassigned?
  end

  test "unassigned? returns false when users assigned" do
    org = create(:organization)
    contact = create(:contact, organization: org)
    user = create(:user, organization: org)
    create(:contact_assignment, contact: contact, user: user)

    assert_not contact.unassigned?
  end
end
