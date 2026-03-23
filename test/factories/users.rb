FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    role { :member }
    organization

    trait :admin do
      role { :admin }
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
