# frozen_string_literal: true

disable_simplecov = ENV['GENERATE_OPENAPI'] == 'true' || ARGV.include?('Rswag::Specs::SwaggerFormatter')

unless disable_simplecov
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter '/spec/'
    add_filter 'app/channels/'
    add_filter 'app/jobs/'
    add_filter 'app/mailers/'
    add_filter 'app/models/jwt_denylist.rb'
    minimum_coverage 95
  end
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'rswag/specs'
require 'shoulda/matchers'
require 'webmock/rspec'
require 'vcr'
require 'uri'

Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('<IPSTACK_KEY>') { ENV.fetch('IPSTACK_ACCESS_KEY', nil) }
  c.allow_http_connections_when_no_cassette = false
  c.register_request_matcher :uri_ignoring_access_key do |request_one, request_two|
    uri_one = URI(request_one.uri)
    uri_two = URI(request_two.uri)

    query_one = Rack::Utils.parse_nested_query(uri_one.query).except('access_key')
    query_two = Rack::Utils.parse_nested_query(uri_two.query).except('access_key')

    [uri_one.scheme, uri_one.host, uri_one.path, query_one] ==
      [uri_two.scheme, uri_two.host, uri_two.path, query_two]
  end
  c.default_cassette_options = {
    record: :once,
    match_requests_on: %i[method uri_ignoring_access_key]
  }
  c.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
  config.include RequestHelpers, type: :request
  config.openapi_root = Rails.root.join('openapi').to_s
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
