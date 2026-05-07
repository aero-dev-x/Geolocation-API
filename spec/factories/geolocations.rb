# frozen_string_literal: true

FactoryBot.define do
  factory :geolocation do
    sequence(:ip)         { |n| "1.1.1.#{(n % 254) + 1}" }
    sequence(:lookup_key) { |n| "1.1.1.#{(n % 254) + 1}" }
    country_name { 'United States' }
    country_code { 'US' }
    region_name  { 'California' }
    region_code  { 'CA' }
    city         { 'Los Angeles' }
    zip          { '90001' }
    latitude     { 34.0655 }
    longitude    { -118.2405 }
    provider_response { { 'ip' => ip } }
    provider { 'ipstack' }

    trait :with_url do
      url { 'https://github.com' }
      lookup_key { 'https://github.com' }
      ip { '140.82.121.4' }
    end
  end
end
