require "test_helper"

class SigningRoleTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:signing_envelope)
    should belong_to(:contact).optional
  end

  context "validations" do
    should validate_presence_of(:label)
  end

  test "label uniqueness within envelope" do
    org = create(:organization)
    user = create(:user, organization: org)
    doc = create(:document, organization: org, user: user)
    envelope = create(:signing_envelope, document: doc, requester: user)
    create(:signing_role, signing_envelope: envelope, label: "Buyer")

    duplicate = build(:signing_role, signing_envelope: envelope, label: "Buyer")
    assert_not duplicate.valid?
  end

  test "display_name returns signer_name or label" do
    role = build(:signing_role, signer_name: "Jane Doe", label: "Buyer")
    assert_equal "Jane Doe", role.display_name

    role2 = build(:signing_role, signer_name: nil, label: "Witness")
    assert_equal "Witness", role2.display_name
  end

  test "self-signer skips email validation" do
    org = create(:organization)
    user = create(:user, organization: org)
    doc = create(:document, organization: org, user: user)
    envelope = create(:signing_envelope, document: doc, requester: user)
    role = build(:signing_role, signing_envelope: envelope, label: "Admin", is_self_signer: true, signer_email: nil)
    assert role.valid?
  end
end
