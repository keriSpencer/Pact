require "test_helper"

class FolderTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:organization)
    should belong_to(:user)
    should belong_to(:parent).optional
    should have_many(:subfolders).dependent(:destroy)
    should have_many(:documents).dependent(:nullify)
  end

  context "validations" do
    should validate_presence_of(:name)
  end

  test "generates path from name for root folder" do
    org = create(:organization)
    user = create(:user, organization: org)
    folder = create(:folder, name: "Contracts", organization: org, user: user)

    assert_equal "/Contracts", folder.path
  end

  test "generates path including parent for nested folder" do
    org = create(:organization)
    user = create(:user, organization: org)
    parent = create(:folder, name: "Documents", organization: org, user: user)
    child = create(:folder, name: "Legal", organization: org, user: user, parent: parent)

    assert_equal "/Documents/Legal", child.path
  end

  test "root? returns true for root folders" do
    folder = build(:folder, parent: nil)
    assert folder.root?
  end

  test "root? returns false for nested folders" do
    org = create(:organization)
    user = create(:user, organization: org)
    parent = create(:folder, organization: org, user: user)
    child = build(:folder, parent: parent)

    assert_not child.root?
  end

  test "breadcrumbs returns path of folders" do
    org = create(:organization)
    user = create(:user, organization: org)
    parent = create(:folder, name: "Root", organization: org, user: user)
    child = create(:folder, name: "Child", organization: org, user: user, parent: parent)

    assert_equal [parent, child], child.breadcrumbs
  end

  test "can_access? allows org members for organization visibility" do
    org = create(:organization)
    user = create(:user, organization: org)
    folder = create(:folder, visibility: :organization, organization: org, user: user)
    other_user = create(:user, organization: org)

    assert folder.can_access?(other_user)
  end

  test "can_access? restricts private folders to owner" do
    org = create(:organization)
    owner = create(:user, organization: org)
    folder = create(:folder, visibility: :folder_private, organization: org, user: owner)
    other_user = create(:user, organization: org)

    assert folder.can_access?(owner)
    assert_not folder.can_access?(other_user)
  end

  test "can_access? rejects users from other orgs" do
    org1 = create(:organization)
    org2 = create(:organization)
    user1 = create(:user, organization: org1)
    user2 = create(:user, organization: org2)
    folder = create(:folder, organization: org1, user: user1)

    assert_not folder.can_access?(user2)
  end

  test "path uniqueness scoped to organization" do
    org = create(:organization)
    user = create(:user, organization: org)
    create(:folder, name: "Test", organization: org, user: user)
    duplicate = build(:folder, name: "Test", organization: org, user: user)

    assert_not duplicate.valid?
  end

  test "same path allowed in different orgs" do
    org1 = create(:organization)
    org2 = create(:organization)
    user1 = create(:user, organization: org1)
    user2 = create(:user, organization: org2)
    create(:folder, name: "Test", organization: org1, user: user1)
    folder2 = build(:folder, name: "Test", organization: org2, user: user2)

    assert folder2.valid?
  end
end
