FactoryBot.define do
  factory :document do
    name { Faker::File.file_name(ext: "pdf") }
    visibility { :organization }
    status { :active }
    organization
    user
    file { Rack::Test::UploadedFile.new(StringIO.new("fake pdf content"), "application/pdf", true, original_filename: "test.pdf") }

    trait :private do
      visibility { :doc_private }
    end

    trait :archived do
      status { :archived }
    end
  end
end
