require "test_helper"

class ContactNoteTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:contact)
    should belong_to(:user).optional
  end

  context "validations" do
    should validate_presence_of(:note)
  end

  test "sets contacted_at on create" do
    note = create(:contact_note, contacted_at: nil)
    assert_not_nil note.contacted_at
  end

  test "contact_type_display returns readable type" do
    note = build(:contact_note, contact_type: "phone")
    assert_equal "Phone Call", note.contact_type_display
  end

  test "contact_type_display handles unknown type" do
    note = build(:contact_note, contact_type: "custom")
    assert_equal "Custom", note.contact_type_display
  end

  test "follow_up_completed? returns true when completed" do
    note = build(:contact_note, :completed)
    assert note.follow_up_completed?
  end

  test "follow_up_completed? returns false when not completed" do
    note = build(:contact_note, :with_follow_up)
    assert_not note.follow_up_completed?
  end

  test "follow_up_overdue? returns true for past dates" do
    note = build(:contact_note, :overdue)
    assert note.follow_up_overdue?
  end

  test "follow_up_overdue? returns false for completed" do
    note = build(:contact_note, :completed)
    assert_not note.follow_up_overdue?
  end

  test "follow_up_due_today? returns true for today" do
    note = build(:contact_note, follow_up_date: Date.current)
    assert note.follow_up_due_today?
  end

  test "complete_follow_up! sets completed_at" do
    note = create(:contact_note, :with_follow_up)
    note.complete_follow_up!
    assert note.follow_up_completed?
  end

  test "follow_up_display shows Today" do
    note = build(:contact_note, follow_up_date: Date.current)
    assert_equal "Today", note.follow_up_display
  end

  test "follow_up_display shows Tomorrow" do
    note = build(:contact_note, follow_up_date: Date.current + 1)
    assert_equal "Tomorrow", note.follow_up_display
  end

  test "follow_up_display shows overdue" do
    note = build(:contact_note, follow_up_date: 3.days.ago.to_date)
    assert_match(/overdue/, note.follow_up_display)
  end

  test "follow_up_display returns nil without date" do
    note = build(:contact_note, follow_up_date: nil)
    assert_nil note.follow_up_display
  end

  test "recent scope orders by contacted_at desc" do
    org = create(:organization)
    contact = create(:contact, organization: org)
    user = create(:user, organization: org)
    old_note = create(:contact_note, contact: contact, user: user, contacted_at: 2.days.ago)
    new_note = create(:contact_note, contact: contact, user: user, contacted_at: 1.hour.ago)

    assert_equal [new_note, old_note], contact.contact_notes.recent.to_a
  end

  test "follow_up_pending scope returns incomplete follow-ups" do
    org = create(:organization)
    contact = create(:contact, organization: org)
    user = create(:user, organization: org)
    pending = create(:contact_note, :with_follow_up, contact: contact, user: user)
    completed = create(:contact_note, :completed, contact: contact, user: user)

    result = ContactNote.follow_up_pending
    assert_includes result, pending
    assert_not_includes result, completed
  end

  test "follow_up_overdue scope returns overdue follow-ups" do
    org = create(:organization)
    contact = create(:contact, organization: org)
    user = create(:user, organization: org)
    overdue = create(:contact_note, :overdue, contact: contact, user: user)
    upcoming = create(:contact_note, :with_follow_up, contact: contact, user: user)

    result = ContactNote.follow_up_overdue
    assert_includes result, overdue
    assert_not_includes result, upcoming
  end
end
