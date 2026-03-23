require "test_helper"

class UserTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:organization)
  end

  context "validations" do
    should validate_presence_of(:email)
  end

  test "full_name returns first and last name" do
    user = build(:user, first_name: "Jane", last_name: "Doe")
    assert_equal "Jane Doe", user.full_name
  end

  test "full_name returns email when no name set" do
    user = build(:user, first_name: nil, last_name: nil, email: "jane@test.com")
    assert_equal "jane@test.com", user.full_name
  end

  test "initials returns first letters of name" do
    user = build(:user, first_name: "Jane", last_name: "Doe")
    assert_equal "JD", user.initials
  end

  test "initials returns first letter of email when no name" do
    user = build(:user, first_name: nil, last_name: nil, email: "jane@test.com")
    assert_equal "J", user.initials
  end

  test "display_name_with_email includes both" do
    user = build(:user, first_name: "Jane", last_name: "Doe", email: "jane@test.com")
    assert_equal "Jane Doe (jane@test.com)", user.display_name_with_email
  end

  test "admin role grants management permissions" do
    user = create(:user, :admin)
    assert user.can_manage_users?
    assert user.can_invite_users?
    assert user.can_view_all_contacts?
  end

  test "member role denies management permissions" do
    user = create(:user, role: :member)
    assert_not user.can_manage_users?
    assert_not user.can_invite_users?
  end

  test "soft_delete! sets deleted_at" do
    user = create(:user)
    user.soft_delete!
    assert user.deleted?
    assert_not_nil user.deleted_at
  end

  test "restore! clears deleted_at" do
    user = create(:user, :deleted)
    user.restore!
    assert_not user.deleted?
    assert_nil user.deleted_at
  end

  test "default scope excludes deleted users" do
    org = create(:organization)
    active_user = create(:user, organization: org)
    deleted_user = create(:user, organization: org)
    deleted_user.soft_delete!

    assert_includes User.all, active_user
    assert_not_includes User.all, deleted_user
  end

  test "with_deleted scope includes deleted users" do
    org = create(:organization)
    user = create(:user, organization: org)
    user.soft_delete!

    assert_includes User.with_deleted, user
  end

  test "deleted user cannot authenticate" do
    user = create(:user)
    user.soft_delete!
    assert_not user.active_for_authentication?
  end

  test "can_delete_user? prevents self-deletion" do
    admin = create(:user, :admin)
    assert_not admin.can_delete_user?(admin)
  end

  test "can_delete_user? allows admin to delete member in same org" do
    org = create(:organization)
    admin = create(:user, :admin, organization: org)
    member = create(:user, organization: org)

    assert admin.can_delete_user?(member)
  end

  test "can_delete_user? prevents cross-org deletion" do
    admin = create(:user, :admin)
    other_member = create(:user)

    assert_not admin.can_delete_user?(other_member)
  end

  test "can_change_user_role? prevents self-role-change" do
    admin = create(:user, :admin)
    assert_not admin.can_change_user_role?(admin)
  end

  test "colleagues returns org users excluding self" do
    org = create(:organization)
    user1 = create(:user, organization: org)
    user2 = create(:user, organization: org)

    assert_includes user1.colleagues, user2
    assert_not_includes user1.colleagues, user1
  end

  test "phone validation accepts valid formats" do
    user = build(:user, phone: "+1 (555) 123-4567")
    assert user.valid?
  end

  test "phone validation rejects invalid formats" do
    user = build(:user, phone: "abc")
    assert_not user.valid?
  end

  test "phone validation allows blank" do
    user = build(:user, phone: "")
    assert user.valid?
  end
end
