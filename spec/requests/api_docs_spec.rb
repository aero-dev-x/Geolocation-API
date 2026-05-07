# frozen_string_literal: true

require 'openapi_helper'

RSpec.describe 'API documentation', type: :request, openapi_spec: 'v1/openapi.json' do
  let(:user) { create(:user) }
  let(:Authorization) { auth_headers(user)['Authorization'] }

  def capture_response_example(example)
    return if response.body.blank?

    example.metadata[:response][:content] ||= {}
    example.metadata[:response][:content]['application/json'] = {
      example: JSON.parse(response.body, symbolize_names: true)
    }
  end

  path '/api/v1/users/sign_up' do
    post 'Registers a user' do
      tags 'Authentication'
      operationId 'signUpUser'
      consumes 'application/json'
      produces 'application/json'
      description 'Creates a user account and returns a 30-minute JWT access token plus a refresh token.'

      parameter name: :payload, in: :body, schema: { '$ref' => '#/components/schemas/sign_up_request' }

      response '201', 'user created' do
        schema '$ref' => '#/components/schemas/user_response'
        header 'Authorization', schema: { type: :string }, description: 'Bearer JWT access token for the created user'

        let(:payload) do
          {
            user: {
              email: 'new@example.com',
              password: 'Password1!',
              password_confirmation: 'Password1!'
            }
          }
        end

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end

      response '422', 'validation error' do
        schema '$ref' => '#/components/schemas/error_response'

        before do
          create(:user, email: 'new@example.com')
        end

        let(:payload) do
          {
            user: {
              email: 'new@example.com',
              password: 'Password1!',
              password_confirmation: 'Password1!'
            }
          }
        end

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end
    end
  end

  path '/api/v1/users/sign_in' do
    post 'Authenticates a user' do
      tags 'Authentication'
      operationId 'signInUser'
      consumes 'application/json'
      produces 'application/json'
      description 'Authenticates an existing user and returns a 30-minute JWT access token plus a refresh token.'

      parameter name: :payload, in: :body, schema: { '$ref' => '#/components/schemas/sign_in_request' }

      response '200', 'authenticated' do
        schema '$ref' => '#/components/schemas/user_response'
        header 'Authorization', schema: { type: :string }, description: 'Bearer JWT access token for the signed-in user'

        let!(:existing_user) { create(:user, email: 'login@example.com', password: 'Password1!') }
        let(:payload) do
          {
            user: {
              email: existing_user.email,
              password: 'Password1!'
            }
          }
        end

        after do |example|
          expect(response.headers['Authorization']).to eq("Bearer #{json_response.dig('data', 'attributes', 'token')}")
          capture_response_example(example)
        end

        run_test!
      end

      response '401', 'invalid credentials' do
        schema '$ref' => '#/components/schemas/error_response'

        let!(:existing_user) { create(:user, email: 'login@example.com', password: 'Password1!') }
        let(:payload) do
          {
            user: {
              email: existing_user.email,
              password: 'wrongpass'
            }
          }
        end

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end
    end
  end

  path '/api/v1/users/refresh_token' do
    post 'Rotates a refresh token' do
      tags 'Authentication'
      operationId 'refreshUserToken'
      consumes 'application/json'
      produces 'application/json'
      description 'Accepts a refresh token and returns a new 30-minute JWT access token plus a newly rotated refresh token.'

      parameter name: :payload, in: :body, schema: { '$ref' => '#/components/schemas/refresh_token_request' }

      response '200', 'tokens refreshed' do
        schema '$ref' => '#/components/schemas/user_response'
        header 'Authorization', schema: { type: :string }, description: 'Bearer JWT access token for the user'

        let!(:existing_user) { create(:user, email: 'refresh@example.com', password: 'Password1!') }
        let(:payload) do
          post '/api/v1/users/sign_in',
               params: { user: { email: existing_user.email, password: 'Password1!' } },
               as: :json

          { refresh_token: json_response.dig('data', 'attributes', 'refresh_token') }
        end

        after do |example|
          expect(response.headers['Authorization']).to eq("Bearer #{json_response.dig('data', 'attributes', 'token')}")
          capture_response_example(example)
        end

        run_test!
      end

      response '401', 'invalid or expired refresh token' do
        schema '$ref' => '#/components/schemas/error_response'
        let(:payload) { { refresh_token: 'invalid-token' } }

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end

      response '400', 'missing refresh token' do
        schema '$ref' => '#/components/schemas/error_response'
        let(:payload) { {} }

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end
    end
  end

  path '/api/v1/users/sign_out' do
    delete 'Revokes the current JWT' do
      tags 'Authentication'
      operationId 'signOutUser'
      security [{ bearerAuth: [] }]
      consumes 'application/json'
      produces 'application/json'
      description 'Revokes the current bearer token. If a refresh token is included, that refresh token is revoked too. The response body is empty. This endpoint currently returns 204 even when the Authorization header is omitted.'

      parameter name: 'Authorization', in: :header, schema: { type: :string }, required: true,
                description: 'Bearer JWT token'
      parameter name: :payload, in: :body, schema: { '$ref' => '#/components/schemas/optional_refresh_token_request' }

      response '204', 'signed out' do
        let!(:existing_user) { create(:user, email: 'logout@example.com', password: 'Password1!') }
        let(:Authorization) do
          post '/api/v1/users/sign_in',
               params: { user: { email: existing_user.email, password: 'Password1!' } },
               as: :json

          response.headers['Authorization']
        end
        let(:payload) do
          {
            refresh_token: json_response.dig('data', 'attributes', 'refresh_token')
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/geolocations' do
    get 'Lists stored geolocations' do
      tags 'Geolocations'
      operationId 'listGeolocations'
      security [{ bearerAuth: [] }]
      produces 'application/json'
      description 'Returns geolocations ordered by newest first, with pagination metadata.'

      parameter name: 'Authorization', in: :header, schema: { type: :string }, required: true,
                description: 'Bearer JWT token'
      parameter name: :'page[number]', in: :query, schema: { type: :integer, minimum: 1 }, required: false,
                description: 'Page number'
      parameter name: :'page[size]', in: :query, schema: { type: :integer, minimum: 1 }, required: false,
                description: 'Page size'

      response '200', 'geolocations returned' do
        schema '$ref' => '#/components/schemas/geolocations_index_response'
        let!(:older_record) do
          create(:geolocation, ip: '1.1.1.10', url: 'https://older.example', created_at: 2.days.ago)
        end
        let!(:newer_record) do
          create(:geolocation, ip: '1.1.1.11', url: 'https://newer.example', created_at: 1.day.ago)
        end
        let(:'page[number]') { 1 }
        let(:'page[size]') { 1 }

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end

      response '401', 'missing or invalid token' do
        schema '$ref' => '#/components/schemas/error_response'
        let(:Authorization) { nil }

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end
    end

    post 'Creates or refreshes a geolocation' do
      tags 'Geolocations'
      operationId 'createGeolocation'
      security [{ bearerAuth: [] }]
      consumes 'application/json'
      produces 'application/json'
      description 'Accepts exactly one of ip or url. Use ip only for literal IP addresses and url only for hostnames or website URLs. Existing records are reused by resolved IP and return 200.'

      parameter name: 'Authorization', in: :header, schema: { type: :string }, required: true,
                description: 'Bearer JWT token'
      parameter name: :payload, in: :body, schema: { '$ref' => '#/components/schemas/geolocation_create_request' }

      let(:provider) { GeolocationProviders::NullProvider.new }
      let(:provider_result) do
        GeolocationProviders::Result.new(
          ip: '64.233.180.113',
          url: nil,
          country_name: 'United States',
          country_code: 'US',
          region_name: 'California',
          region_code: 'CA',
          city: 'Mountain View',
          zip: '94041',
          latitude: 37.38801956176758,
          longitude: -122.07431030273438,
          provider_response: { 'ip' => '64.233.180.113', 'connection' => { 'isp' => 'Google' } }
        )
      end

      before do
        allow(Rails.configuration).to receive(:geolocation_provider).and_return(provider)
        allow(provider).to receive(:lookup).and_return(provider_result)
      end

      response '201', 'created from ip' do
        schema '$ref' => '#/components/schemas/geolocation_response'
        let(:payload) do
          { geolocation: { ip: '1.2.3.4' } }
        end

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end

      response '200', 'updated existing record' do
        schema '$ref' => '#/components/schemas/geolocation_response'

        before do
          create(
            :geolocation,
            ip: '64.233.180.113',
            city: 'Old City',
            provider: 'null'
          )
        end

        let(:payload) do
          { geolocation: { ip: '1.2.3.4' } }
        end

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end

      response '422', 'invalid url' do
        schema '$ref' => '#/components/schemas/error_response'
        let(:payload) do
          { geolocation: { url: 'https:///' } }
        end

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end

      response '400', 'missing ip and url' do
        schema '$ref' => '#/components/schemas/error_response'
        let(:payload) do
          {}
        end

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end

      response '401', 'missing or invalid token' do
        schema '$ref' => '#/components/schemas/error_response'
        let(:Authorization) { nil }
        let(:payload) do
          { geolocation: { ip: '1.2.3.4' } }
        end

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end
    end
  end

  path '/api/v1/geolocations/{identifier}' do
    parameter name: :identifier, in: :path, schema: { type: :string }, required: true,
              description: 'Record identifier. Can match ip or url. URL-based values must be URL-encoded.'
    parameter name: 'Authorization', in: :header, schema: { type: :string }, required: true,
              description: 'Bearer JWT token'

    get 'Fetches a geolocation by identifier' do
      tags 'Geolocations'
      operationId 'showGeolocation'
      security [{ bearerAuth: [] }]
      produces 'application/json'

      response '200', 'geolocation found' do
        schema '$ref' => '#/components/schemas/geolocation_response'

        let!(:geolocation) { create(:geolocation, ip: '1.2.3.4') }
        let(:identifier) { geolocation.ip }

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end

      response '200', 'geolocation found by url identifier' do
        schema '$ref' => '#/components/schemas/geolocation_response'

        let!(:geolocation) do
          create(:geolocation, ip: '64.233.180.113', url: 'https://google.com')
        end
        let(:identifier) { CGI.escape(geolocation.url) }

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end

      response '404', 'geolocation not found' do
        schema '$ref' => '#/components/schemas/error_response'
        let(:identifier) { 'missing' }

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end
    end

    delete 'Deletes a geolocation by identifier' do
      tags 'Geolocations'
      operationId 'deleteGeolocation'
      security [{ bearerAuth: [] }]
      produces 'application/json'

      response '204', 'geolocation deleted' do
        let!(:geolocation) { create(:geolocation, ip: '1.2.3.4') }
        let(:identifier) { geolocation.ip }

        run_test!
      end

      response '204', 'geolocation deleted by url identifier' do
        let!(:geolocation) do
          create(:geolocation, ip: '64.233.180.113', url: 'https://google.com')
        end
        let(:identifier) { CGI.escape(geolocation.url) }

        run_test!
      end

      response '404', 'geolocation not found' do
        schema '$ref' => '#/components/schemas/error_response'
        let(:identifier) { 'missing' }

        after do |example|
          capture_response_example(example)
        end

        run_test!
      end
    end
  end
end
