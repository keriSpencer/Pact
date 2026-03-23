require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  context "validations" do
    subject { build(:organization) }

    should validate_presence_of(:name)
    should validate_uniqueness_of(:slug)
  end

  context "associations" do
    should have_many(:users).dependent(:destroy)
  end

  test "generates slug from name on create" do
    org = Organization.create!(name: "Acme Corp")
    assert_equal "acme-corp", org.slug
  end

  test "generates unique slug when duplicate exists" do
    Organization.create!(name: "Acme Corp")
    org2 = Organization.create!(name: "Acme Corp")
    assert_equal "acme-corp-1", org2.slug
  end

  test "does not overwrite existing slug" do
    org = Organization.create!(name: "Acme Corp", slug: "custom-slug")
    assert_equal "custom-slug", org.slug
  end

  test "slug format validation rejects uppercase" do
    org = Organization.new(name: "Test", slug: "INVALID")
    assert_not org.valid?
    assert_includes org.errors[:slug], "only allows lowercase letters, numbers, and hyphens"
  end

  test "active scope returns only active organizations" do
    active_org = create(:organization, active: true)
    inactive_org = create(:organization, active: false)

    assert_includes Organization.active, active_org
    assert_not_includes Organization.active, inactive_org
  end

  test "admins returns only admin users" do
    org = create(:organization)
    admin = create(:user, :admin, organization: org)
    member = create(:user, organization: org)

    assert_includes org.admins, admin
    assert_not_includes org.admins, member
  end

  test "primary_admin returns first admin by creation date" do
    org = create(:organization)
    first_admin = create(:user, :admin, organization: org)
    create(:user, :admin, organization: org)

    assert_equal first_admin, org.primary_admin
  end

  test "member_count returns number of users" do
    org = create(:organization)
    create_list(:user, 3, organization: org)

    assert_equal 3, org.member_count
  end
end
