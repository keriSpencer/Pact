source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "sqlite3", ">= 2.1", group: [:development, :test]
gem "pg", "~> 1.5", group: :production
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

gem "tzinfo-data", platforms: %i[ windows jruby ]

# Database-backed adapters
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false

# Authentication
gem "devise"
gem "devise_invitable"

# PDF processing
gem "hexapdf"

# Pagination
gem "pagy"

# Deploy
gem "kamal", require: false
gem "thruster", require: false

# Active Storage - AWS S3 for production
gem "aws-sdk-s3", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "dotenv-rails"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "shoulda-context"
  gem "minitest", "~> 5.25"
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

gem "stripe", "~> 19.0"

gem "ruby_native", "~> 0.4.1"

gem "action_push_native", "~> 0.3.1"
