FactoryBot.define do
  factory :folder do
    name { Faker::Lorem.word.capitalize }
    visibility { :organization }
    organization
    user

    trait :private do
      visibility { :folder_private }
    end

    trait :with_parent do
      association :parent, factory: :folder
    end
  end
end
