require "test_helper"

class SigningEnvelopeTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:document)
    should belong_to(:requester)
    should have_many(:signing_roles).dependent(:destroy)
    should have_many(:signature_requests).dependent(:destroy)
  end

  test "default status is draft" do
    org = create(:organization)
    user = create(:user, organization: org)
    doc = create(:document, organization: org, user: user)
    envelope = SigningEnvelope.create!(document: doc, requester: user)
    assert envelope.draft?
  end

  test "completion_progress returns percentage" do
    org = create(:organization)
    user = create(:user, organization: org)
    doc = create(:document, organization: org, user: user)
    envelope = create(:signing_envelope, document: doc, requester: user)
    role1 = create(:signing_role, signing_envelope: envelope, label: "A")
    role2 = create(:signing_role, signing_envelope: envelope, label: "B")

    assert_equal 0, envelope.completion_progress
  end

  test "parallel mode allows all signers to sign" do
    org = create(:organization)
    user = create(:user, organization: org)
    doc = create(:document, organization: org, user: user)
    envelope = create(:signing_envelope, document: doc, requester: user, signing_mode: :parallel, status: :active)
    role1 = create(:signing_role, signing_envelope: envelope, label: "A", signing_order: 0)
    role2 = create(:signing_role, signing_envelope: envelope, label: "B", signing_order: 1)

    assert envelope.can_signer_sign?(role1)
    assert envelope.can_signer_sign?(role2)
  end

  test "sequential mode only allows current order to sign" do
    org = create(:organization)
    user = create(:user, organization: org)
    doc = create(:document, organization: org, user: user)
    envelope = create(:signing_envelope, document: doc, requester: user, signing_mode: :sequential, status: :active)
    role1 = create(:signing_role, signing_envelope: envelope, label: "First", signing_order: 0)
    role2 = create(:signing_role, signing_envelope: envelope, label: "Second", signing_order: 1)

    assert envelope.can_signer_sign?(role1)
    assert_not envelope.can_signer_sign?(role2)
  end
end
