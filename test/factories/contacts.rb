FactoryBot.define do
  factory :contact do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.phone_number }
    company { Faker::Company.name }
    title { Faker::Job.title }
    organization

    trait :with_linkedin do
      linkedin_url { "https://linkedin.com/in/#{Faker::Internet.slug}" }
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end

  factory :contact_assignment do
    contact
    user
    assigned_at { Time.current }
  end
end
