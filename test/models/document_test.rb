require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:organization)
    should belong_to(:user)
    should belong_to(:folder).optional
    should belong_to(:contact).optional
    should have_many(:versions).dependent(:destroy)
  end

  context "validations" do
    should validate_presence_of(:name)
  end

  test "extracts file metadata on create" do
    org = create(:organization)
    user = create(:user, organization: org)
    doc = create(:document, organization: org, user: user)

    assert_not_nil doc.file_size
    assert_not_nil doc.content_type
  end

  test "formatted_file_size returns human readable size" do
    doc = build(:document, file_size: 1024)
    assert_equal "1.0 KB", doc.formatted_file_size
  end

  test "formatted_file_size returns MB for larger files" do
    doc = build(:document, file_size: 1024 * 1024 * 2.5)
    assert_equal "2.5 MB", doc.formatted_file_size
  end

  test "formatted_file_size returns Unknown when nil" do
    doc = build(:document, file_size: nil)
    assert_equal "Unknown", doc.formatted_file_size
  end

  test "file_type_category returns correct type" do
    org = create(:organization)
    user = create(:user, organization: org)
    doc = create(:document, organization: org, user: user)

    assert_equal "pdf", doc.file_type_category
  end

  test "can_access? allows document owner" do
    org = create(:organization)
    user = create(:user, organization: org)
    doc = create(:document, organization: org, user: user, visibility: :doc_private)

    assert doc.can_access?(user)
  end

  test "can_access? allows admins" do
    org = create(:organization)
    user = create(:user, organization: org)
    admin = create(:user, :admin, organization: org)
    doc = create(:document, organization: org, user: user, visibility: :doc_private)

    assert doc.can_access?(admin)
  end

  test "can_access? restricts private docs from non-owners" do
    org = create(:organization)
    owner = create(:user, organization: org)
    other = create(:user, organization: org)
    doc = create(:document, organization: org, user: owner, visibility: :doc_private)

    assert_not doc.can_access?(other)
  end

  test "can_access? allows org visibility for org members" do
    org = create(:organization)
    owner = create(:user, organization: org)
    other = create(:user, organization: org)
    doc = create(:document, organization: org, user: owner, visibility: :organization)

    assert doc.can_access?(other)
  end

  test "derived_status returns draft by default" do
    doc = build(:document)
    assert_equal :draft, doc.derived_status
  end
end
