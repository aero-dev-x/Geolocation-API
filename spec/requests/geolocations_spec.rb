# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe 'Geolocations API', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:provider) { GeolocationProviders::NullProvider.new }
  let(:result) do
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
    allow(provider).to receive(:lookup).and_return(result)
  end

  describe 'GET /api/v1/geolocations' do
    let!(:older_record) { create(:geolocation, lookup_key: 'older.example', url: 'https://older.example', created_at: 2.days.ago) }
    let!(:newer_record) { create(:geolocation, lookup_key: 'newer.example', url: 'https://newer.example', created_at: 1.day.ago) }

    it 'returns records ordered by newest first' do
      get '/api/v1/geolocations', headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response.dig('data', 0, 'attributes', 'lookup_key')).to eq(newer_record.lookup_key)
      expect(json_response.dig('data', 1, 'attributes', 'lookup_key')).to eq(older_record.lookup_key)
    end

    it 'returns pagination metadata for the requested page' do
      get '/api/v1/geolocations', params: { page: { number: 1, size: 1 } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data'].size).to eq(1)
      expect(json_response['meta']).to eq(
        'total_count' => 2,
        'page' => 1,
        'per_page' => 1
      )
    end

    it 'requires authentication' do
      get '/api/v1/geolocations'

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/geolocations/:lookup_key' do
    let!(:geolocation) { create(:geolocation, lookup_key: '1.2.3.4', ip: '1.2.3.4') }

    it 'returns the requested record' do
      get '/api/v1/geolocations/1.2.3.4', headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response.dig('data', 'attributes', 'lookup_key')).to eq('1.2.3.4')
    end

    it 'supports URL-encoded lookup keys' do
      url_geolocation = create(:geolocation, :with_url)

      get "/api/v1/geolocations/#{CGI.escape(url_geolocation.lookup_key)}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response.dig('data', 'attributes', 'lookup_key')).to eq(url_geolocation.lookup_key)
    end

    it 'returns not found for an unknown lookup key' do
      get '/api/v1/geolocations/missing', headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_response.dig('errors', 0, 'code')).to eq('not_found')
    end

    it 'requires authentication' do
      get '/api/v1/geolocations/1.2.3.4'

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/geolocations' do
    let(:ip_params) do
      {
        data: {
          type: 'geolocations',
          attributes: { ip: '1.2.3.4' }
        }
      }
    end
    let(:url_params) do
      {
        data: {
          type: 'geolocations',
          attributes: { url: 'google.com' }
        }
      }
    end

    it 'creates a geolocation for an IP address' do
      expect do
        post '/api/v1/geolocations', params: ip_params, headers: headers, as: :json
      end.to change(Geolocation, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response.dig('data', 'attributes', 'ip')).to eq('64.233.180.113')
      expect(json_response.dig('data', 'attributes', 'city')).to eq('Mountain View')
      expect(json_response.dig('data', 'attributes', 'provider')).to eq('null')
    end

    it 'creates a geolocation for a hostname and stores the normalized lookup key' do
      allow(Resolv).to receive(:getaddress).with('google.com').and_return('64.233.180.113')

      post '/api/v1/geolocations', params: url_params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json_response.dig('data', 'attributes', 'url')).to eq('https://google.com')
      expect(json_response.dig('data', 'attributes', 'lookup_key')).to eq('https://google.com')
      expect(json_response.dig('data', 'attributes', 'ip')).to eq('64.233.180.113')
      expect(json_response.dig('data', 'attributes', 'city')).to eq('Mountain View')
    end

    it 'updates an existing record for the same lookup key' do
      geolocation = create(
        :geolocation,
        lookup_key: '1.2.3.4',
        ip: '9.9.9.9',
        city: 'Old City',
        provider: 'null'
      )

      expect do
        post '/api/v1/geolocations', params: ip_params, headers: headers, as: :json
      end.not_to change(Geolocation, :count)

      expect(response).to have_http_status(:ok)
      expect(geolocation.reload.city).to eq('Mountain View')
      expect(geolocation.provider).to eq('null')
    end

    it 'returns an error when neither ip nor url is provided' do
      post '/api/v1/geolocations',
           params: { data: { type: 'geolocations', attributes: {} } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json_response.dig('errors', 0, 'code')).to eq('missing_parameter')
    end

    it 'returns an error when the data wrapper is missing' do
      post '/api/v1/geolocations', params: {}, headers: headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json_response.dig('errors', 0, 'code')).to eq('missing_parameter')
    end

    it 'returns an error when both ip and url are provided' do
      post '/api/v1/geolocations',
           params: { data: { type: 'geolocations', attributes: { ip: '1.2.3.4', url: 'https://example.com' } } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json_response.dig('errors', 0, 'code')).to eq('ambiguous_parameter')
    end

    it 'returns an error for an invalid IP address' do
      post '/api/v1/geolocations',
           params: { data: { type: 'geolocations', attributes: { ip: '999.999.999.999' } } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig('errors', 0, 'code')).to eq('invalid_ip')
    end

    it 'returns an error for an invalid URL' do
      post '/api/v1/geolocations',
           params: { data: { type: 'geolocations', attributes: { url: 'https:///' } } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig('errors', 0, 'code')).to eq('invalid_url')
    end

    it 'returns an error when DNS resolution fails' do
      allow(Resolv).to receive(:getaddress).and_raise(Resolv::ResolvError)

      post '/api/v1/geolocations',
           params: { data: { type: 'geolocations', attributes: { url: 'missing.example' } } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig('errors', 0, 'code')).to eq('dns_resolution_failed')
    end

    it 'returns an error when the provider quota is exceeded' do
      allow(provider).to receive(:lookup).and_raise(GeolocationProviders::QuotaError, 'quota exceeded')

      post '/api/v1/geolocations', params: ip_params, headers: headers, as: :json

      expect(response).to have_http_status(:too_many_requests)
      expect(json_response.dig('errors', 0, 'code')).to eq('quota_exceeded')
    end

    it 'returns an error when the provider raises a generic error' do
      allow(provider).to receive(:lookup).and_raise(GeolocationProviders::ProviderError, 'provider unavailable')

      post '/api/v1/geolocations', params: ip_params, headers: headers, as: :json

      expect(response).to have_http_status(:bad_gateway)
      expect(json_response.dig('errors', 0, 'code')).to eq('provider_error')
    end

    it 'returns an error when the provider times out' do
      allow(provider).to receive(:lookup).and_raise(GeolocationProviders::TimeoutError, 'timeout')

      post '/api/v1/geolocations', params: ip_params, headers: headers, as: :json

      expect(response).to have_http_status(:gateway_timeout)
      expect(json_response.dig('errors', 0, 'code')).to eq('provider_timeout')
    end

    it 'returns a validation error when persistence fails' do
      record = Geolocation.new
      record.errors.add(:provider, 'is not included in the list')
      error = ActiveRecord::RecordInvalid.new(record)

      allow_any_instance_of(GeolocationLookupService).to receive(:call).and_raise(error)

      post '/api/v1/geolocations', params: ip_params, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig('errors', 0, 'code')).to eq('validation_error')
    end

    it 'returns an internal error for unexpected failures' do
      allow_any_instance_of(GeolocationLookupService).to receive(:call).and_raise(StandardError, 'boom')

      post '/api/v1/geolocations', params: ip_params, headers: headers, as: :json

      expect(response).to have_http_status(:internal_server_error)
      expect(json_response.dig('errors', 0, 'code')).to eq('internal_error')
    end

    it 'requires authentication' do
      post '/api/v1/geolocations', params: ip_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/geolocations/:lookup_key' do
    it 'deletes the geolocation identified by its lookup key' do
      create(:geolocation, lookup_key: '5.5.5.5', ip: '5.5.5.5')

      expect do
        delete '/api/v1/geolocations/5.5.5.5', headers: headers
      end.to change(Geolocation, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'deletes a record with a URL lookup key' do
      geolocation = create(:geolocation, :with_url)

      expect do
        delete "/api/v1/geolocations/#{CGI.escape(geolocation.lookup_key)}", headers: headers
      end.to change(Geolocation, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns not found for an unknown lookup key' do
      delete '/api/v1/geolocations/missing', headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_response.dig('errors', 0, 'code')).to eq('not_found')
    end

    it 'requires authentication' do
      delete '/api/v1/geolocations/missing'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
# rubocop:enable Metrics/BlockLength
