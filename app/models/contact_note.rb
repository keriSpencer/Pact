class ContactNote < ApplicationRecord
  belongs_to :contact
  belongs_to :user, optional: true

  validates :note, presence: true
  validates :contacted_at, presence: true

  before_validation :set_contacted_at, on: :create

  scope :recent, -> { order(contacted_at: :desc) }
  scope :with_follow_up, -> { where.not(follow_up_date: nil) }
  scope :follow_up_pending, -> { with_follow_up.where(follow_up_completed_at: nil) }
  scope :follow_up_completed, -> { with_follow_up.where.not(follow_up_completed_at: nil) }
  scope :follow_up_overdue, -> { follow_up_pending.where("contact_notes.follow_up_date < ?", Date.current) }
  scope :follow_up_due_today, -> { follow_up_pending.where("contact_notes.follow_up_date = ?", Date.current) }
  scope :follow_up_upcoming, -> { follow_up_pending.where("contact_notes.follow_up_date > ?", Date.current) }

  CONTACT_TYPES = [
    ["Phone Call", "phone"],
    ["Email", "email"],
    ["Meeting", "meeting"],
    ["Text/SMS", "text"],
    ["LinkedIn", "linkedin"],
    ["Other", "other"]
  ].freeze

  def contact_type_display
    CONTACT_TYPES.find { |display, value| value == contact_type }&.first || contact_type&.humanize || "Contact"
  end

  def follow_up_completed?
    follow_up_completed_at.present?
  end

  def follow_up_overdue?
    follow_up_date.present? && !follow_up_completed? && follow_up_date < Date.current
  end

  def follow_up_due_today?
    follow_up_date.present? && !follow_up_completed? && follow_up_date == Date.current
  end

  def complete_follow_up!
    update!(follow_up_completed_at: Time.current)
  end

  def follow_up_display
    return nil unless follow_up_date.present?

    days_until = (follow_up_date - Date.current).to_i

    case days_until
    when -Float::INFINITY..-2
      "#{days_until.abs} #{'day'.pluralize(days_until.abs)} overdue"
    when -1
      "Yesterday"
    when 0
      "Today"
    when 1
      "Tomorrow"
    when 2..6
      "In #{days_until} days"
    else
      follow_up_date.strftime("%b %d, %Y")
    end
  end

  private

  def set_contacted_at
    self.contacted_at ||= Time.current
  end
end
