FactoryBot.define do
  factory :contact_note do
    contact
    user
    note { Faker::Lorem.paragraph }
    contact_type { ContactNote::CONTACT_TYPES.sample.last }
    contacted_at { Time.current }

    trait :with_follow_up do
      follow_up_date { 3.days.from_now.to_date }
    end

    trait :overdue do
      follow_up_date { 2.days.ago.to_date }
    end

    trait :completed do
      follow_up_date { 1.day.ago.to_date }
      follow_up_completed_at { Time.current }
    end
  end
end
