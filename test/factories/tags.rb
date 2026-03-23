FactoryBot.define do
  factory :tag do
    name { Faker::Lorem.unique.word.capitalize }
    color { Tag::COLORS.sample }
    organization
  end

  factory :contact_tag do
    contact
    tag
  end
end
