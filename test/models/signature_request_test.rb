require "test_helper"

class SignatureRequestTest < ActiveSupport::TestCase
  setup do
    @organization = create(:organization)
    @user = create(:user, organization: @organization)
    @document = create(:document, organization: @organization, user: @user)
  end

  test "valid with required attributes" do
    sr = build(:signature_request, document: @document, requester: @user)
    assert sr.valid?
  end

  test "generates signature_token on create" do
    sr = SignatureRequest.new(
      document: @document,
      requester: @user,
      signer_email: "test@example.com",
      signer_name: "Test Signer"
    )
    sr.save!
    assert sr.signature_token.present?
  end

  test "requires signer_email unless draft" do
    sr = build(:signature_request, document: @document, requester: @user, signer_email: nil, status: :pending)
    assert_not sr.valid?
    assert sr.errors[:signer_email].any?
  end

  test "draft does not require signer_email" do
    sr = build(:signature_request, :draft, document: @document, requester: @user, signer_email: "")
    assert sr.valid?
  end

  test "signature_token is unique" do
    sr1 = create(:signature_request, document: @document, requester: @user)
    sr2 = build(:signature_request, document: @document, requester: @user, signature_token: sr1.signature_token)
    assert_not sr2.valid?
  end

  test "can_sign? returns true for pending, sent, viewed" do
    %i[pending sent viewed].each do |status|
      sr = build(:signature_request, document: @document, requester: @user, status: status)
      assert sr.can_sign?, "Expected can_sign? to be true for #{status}"
    end
  end

  test "can_sign? returns false for signed, declined, expired, cancelled, voided" do
    %i[signed declined expired cancelled voided].each do |status|
      sr = build(:signature_request, document: @document, requester: @user, status: status)
      assert_not sr.can_sign?, "Expected can_sign? to be false for #{status}"
    end
  end

  test "signer_display_name returns name when present" do
    sr = build(:signature_request, signer_name: "Alice", signer_email: "alice@example.com")
    assert_equal "Alice", sr.signer_display_name
  end

  test "signer_display_name returns email when name blank" do
    sr = build(:signature_request, signer_name: nil, signer_email: "alice@example.com")
    assert_equal "alice@example.com", sr.signer_display_name
  end

  test "status_color_class returns appropriate classes" do
    sr = build(:signature_request, status: :signed)
    assert_includes sr.status_color_class, "green"

    sr.status = :pending
    assert_includes sr.status_color_class, "yellow"

    sr.status = :declined
    assert_includes sr.status_color_class, "red"
  end

  test "auto_match_contact finds matching contact" do
    contact = create(:contact, organization: @organization, email: "signer@example.com")
    sr = SignatureRequest.new(
      document: @document,
      requester: @user,
      signer_email: "signer@example.com",
      signer_name: "Test"
    )
    sr.valid?
    assert_equal contact, sr.contact
    assert sr.auto_matched?
  end

  test "auto_match_contact does not match non-existent email" do
    sr = SignatureRequest.new(
      document: @document,
      requester: @user,
      signer_email: "nobody@example.com",
      signer_name: "Test"
    )
    sr.valid?
    assert_nil sr.contact
    assert_not sr.auto_matched?
  end

  test "cancel! changes status to cancelled" do
    sr = create(:signature_request, document: @document, requester: @user, status: :sent)
    assert sr.cancel!
    assert sr.cancelled?
  end

  test "cancel! returns false for already signed" do
    sr = create(:signature_request, :signed, document: @document, requester: @user)
    assert_not sr.cancel!
  end

  test "stale_drafts scope finds old drafts" do
    old_draft = create(:signature_request, :draft, document: @document, requester: @user)
    old_draft.update_column(:updated_at, 8.days.ago)

    recent_draft = create(:signature_request, :draft, document: @document, requester: @user)

    assert_includes SignatureRequest.stale_drafts, old_draft
    assert_not_includes SignatureRequest.stale_drafts, recent_draft
  end

  test "mark_as_viewed! updates status from sent" do
    sr = create(:signature_request, :sent, document: @document, requester: @user)
    sr.mark_as_viewed!
    assert sr.viewed?
    assert_not_nil sr.viewed_at
  end

  test "mark_as_viewed! does nothing when already signed" do
    sr = create(:signature_request, :signed, document: @document, requester: @user)
    sr.mark_as_viewed!
    assert sr.signed? # still signed
  end

  test "void! changes status and records voided_by" do
    sr = create(:signature_request, document: @document, requester: @user, status: :sent)
    admin = create(:user, :admin, organization: @organization)
    assert sr.void!(admin)
    sr.reload
    assert sr.voided?
    assert_equal admin, sr.voided_by
    assert_not_nil sr.voided_at
  end
end
