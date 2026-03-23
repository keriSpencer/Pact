FactoryBot.define do
  factory :signature_request do
    document
    association :requester, factory: :user
    signer_email { Faker::Internet.email }
    signer_name { Faker::Name.name }
    status { :pending }
    signature_token { SecureRandom.urlsafe_base64(32) }

    trait :draft do
      status { :draft }
      signer_email { "" }
    end

    trait :sent do
      status { :sent }
      sent_at { Time.current }
    end

    trait :signed do
      status { :signed }
      signed_at { Time.current }
      signature_data { "John Doe" }
    end

    trait :declined do
      status { :declined }
      decline_reason { "Not the right document" }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :voided do
      status { :voided }
      voided_at { Time.current }
      association :voided_by, factory: :user
    end
  end
end
