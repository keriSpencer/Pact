require "test_helper"

class TagTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:organization)
    should have_many(:contact_tags).dependent(:destroy)
    should have_many(:contacts).through(:contact_tags)
  end

  context "validations" do
    subject { build(:tag) }

    should validate_presence_of(:name)
    should validate_presence_of(:color)
    should validate_uniqueness_of(:name).scoped_to(:organization_id).case_insensitive
  end

  test "name uniqueness scoped to organization" do
    org = create(:organization)
    create(:tag, name: "VIP", organization: org)
    duplicate = build(:tag, name: "VIP", organization: org)

    assert_not duplicate.valid?
  end

  test "same name allowed in different orgs" do
    org1 = create(:organization)
    org2 = create(:organization)
    create(:tag, name: "VIP", organization: org1)
    tag2 = build(:tag, name: "VIP", organization: org2)

    assert tag2.valid?
  end

  test "bg_class returns correct tailwind class" do
    tag = build(:tag, color: "blue")
    assert_equal "bg-blue-100", tag.bg_class
  end

  test "text_class returns correct tailwind class" do
    tag = build(:tag, color: "red")
    assert_equal "text-red-700", tag.text_class
  end

  test "bg_class defaults for unknown color" do
    tag = build(:tag, color: "unknown")
    assert_equal "bg-gray-100", tag.bg_class
  end

  test "ordered scope sorts by name" do
    org = create(:organization)
    z_tag = create(:tag, name: "Zebra", organization: org)
    a_tag = create(:tag, name: "Alpha", organization: org)

    assert_equal [a_tag, z_tag], org.tags.ordered.to_a
  end
end
