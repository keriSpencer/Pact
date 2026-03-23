require "test_helper"

class DocumentShareTest < ActiveSupport::TestCase
  setup do
    @organization = create(:organization)
    @user = create(:user, organization: @organization)
    @contact = create(:contact, organization: @organization)
    @document = create(:document, organization: @organization, user: @user)
  end

  test "valid with user recipient" do
    share = build(:document_share, :with_user, document: @document, shared_by: @user, user: @user)
    assert share.valid?
  end

  test "valid with contact recipient" do
    share = build(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact)
    assert share.valid?
  end

  test "invalid without any recipient" do
    share = build(:document_share, document: @document, shared_by: @user)
    assert_not share.valid?
    assert_includes share.errors.full_messages.join, "user or a contact"
  end

  test "generates share_token for contact shares" do
    share = create(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact)
    assert share.share_token.present?
  end

  test "does not generate share_token for user shares" do
    share = create(:document_share, :with_user, document: @document, shared_by: @user, user: @user)
    assert_nil share.share_token
  end

  test "contacts cannot have edit permission" do
    share = build(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact, permission_level: :edit)
    assert_not share.valid?
  end

  test "contacts cannot have admin permission" do
    share = build(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact, permission_level: :admin)
    assert_not share.valid?
  end

  test "contacts can have sign_only permission" do
    share = build(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact, permission_level: :sign_only)
    assert share.valid?
  end

  test "expired? returns true when past expiry" do
    share = build(:document_share, :with_user, :expired, document: @document, shared_by: @user, user: @user)
    assert share.expired?
  end

  test "active? returns true when not expired" do
    share = build(:document_share, :with_user, document: @document, shared_by: @user, user: @user, expires_at: 1.day.from_now)
    assert share.active?
  end

  test "record_access! updates access fields" do
    share = create(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact)
    assert_equal 0, share.access_count
    assert_nil share.first_access_at

    share.record_access!
    share.reload

    assert_equal 1, share.access_count
    assert_not_nil share.first_access_at
    assert_not_nil share.accessed_at
  end

  test "recipient returns user when present" do
    share = build(:document_share, :with_user, document: @document, shared_by: @user, user: @user)
    assert_equal @user, share.recipient
  end

  test "recipient returns contact when user is nil" do
    share = build(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact)
    assert_equal @contact, share.recipient
  end

  test "recipient_name returns user name" do
    share = build(:document_share, :with_user, document: @document, shared_by: @user, user: @user)
    assert_equal @user.full_name, share.recipient_name
  end

  test "recipient_email returns contact email" do
    share = build(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact)
    assert_equal @contact.email, share.recipient_email
  end

  test "external? is true for contact shares without user" do
    share = build(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact)
    assert share.external?
  end

  test "can_view? is true for active view shares" do
    share = build(:document_share, :with_user, document: @document, shared_by: @user, user: @user, permission_level: :view)
    assert share.can_view?
  end

  test "can_sign? is true for active sign_only shares" do
    share = build(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact, permission_level: :sign_only)
    assert share.can_sign?
  end

  test "uniqueness scoped to document for user" do
    create(:document_share, :with_user, document: @document, shared_by: @user, user: @user)
    duplicate = build(:document_share, :with_user, document: @document, shared_by: @user, user: @user)
    assert_not duplicate.valid?
  end

  test "uniqueness scoped to document for contact" do
    create(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact)
    duplicate = build(:document_share, :with_contact, document: @document, shared_by: @user, contact: @contact)
    assert_not duplicate.valid?
  end

  test "active scope excludes expired shares" do
    active = create(:document_share, :with_user, document: @document, shared_by: @user, user: @user, expires_at: 1.day.from_now)
    user2 = create(:user, organization: @organization)
    expired = create(:document_share, :with_user, :expired, document: @document, shared_by: @user, user: user2)

    assert_includes DocumentShare.active, active
    assert_not_includes DocumentShare.active, expired
  end
end
