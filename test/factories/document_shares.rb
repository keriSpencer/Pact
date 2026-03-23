FactoryBot.define do
  factory :document_share do
    document
    association :shared_by, factory: :user
    permission_level { :view }

    trait :with_user do
      user
    end

    trait :with_contact do
      contact
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :sign_only do
      permission_level { :sign_only }
    end
  end
end
