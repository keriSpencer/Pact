FactoryBot.define do
  factory :signature_template do
    name { Faker::Lorem.words(number: 3).join(" ").titleize }
    description { Faker::Lorem.sentence }
    document
    user
    organization
    use_count { 0 }

    trait :with_fields do
      after(:create) do |template|
        create(:signature_template_field, signature_template: template, position: 0, field_type: "signature")
        create(:signature_template_field, signature_template: template, position: 1, field_type: "date")
      end
    end
  end

  factory :signature_template_field do
    signature_template
    page_number { 1 }
    x_percent { rand(10.0..80.0).round(2) }
    y_percent { rand(10.0..80.0).round(2) }
    width_percent { 25.0 }
    height_percent { 8.0 }
    field_type { "signature" }
    required { true }
    position { 0 }
  end
end
