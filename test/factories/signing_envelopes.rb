FactoryBot.define do
  factory :signing_envelope do
    document
    association :requester, factory: :user
    signing_mode { :parallel }
    status { :draft }

    trait :with_roles do
      after(:create) do |envelope|
        create(:signing_role, signing_envelope: envelope, label: "Signer 1", color: "#3B82F6", signing_order: 0)
        create(:signing_role, signing_envelope: envelope, label: "Signer 2", color: "#EF4444", signing_order: 1)
      end
    end

    trait :sequential do
      signing_mode { :sequential }
    end
  end

  factory :signing_role do
    signing_envelope
    label { "Signer #{rand(100)}" }
    color { SigningRole::COLORS.sample }
    signer_email { Faker::Internet.email }
    signer_name { Faker::Name.name }
    signing_order { 0 }
    is_self_signer { false }

    trait :self_signer do
      is_self_signer { true }
      signer_email { nil }
      signer_name { nil }
    end
  end
end
