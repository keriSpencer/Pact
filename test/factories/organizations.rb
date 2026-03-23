FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    slug { Faker::Internet.slug(glue: "-") }
    active { true }
  end
end
