# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.1'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.6'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

gem 'devise', '~> 5.0'
gem 'devise-jwt', '~> 0.13.0'

gem 'faraday', '~> 2.14'
gem 'faraday-retry', '~> 2.4'
gem 'jsonapi-serializer', '~> 2.2'
gem 'kaminari', '~> 1.2'
gem 'rack-attack', '~> 6.8'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem 'rack-cors'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 7.1'
  gem 'rswag-api'
  gem 'rswag-specs'
  gem 'rswag-ui'
end

group :test do
  gem 'database_cleaner-active_record'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'annotate'
  gem 'rubocop',             require: false
  gem 'rubocop-rails',       require: false
  gem 'rubocop-rspec',       require: false
end
