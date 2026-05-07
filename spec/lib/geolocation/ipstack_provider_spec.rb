# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe GeolocationProviders::IpstackProvider do
  describe '.new' do
    it 'requires an access key' do
      expect { described_class.new(access_key: nil) }.to raise_error(ArgumentError, 'IPSTACK_ACCESS_KEY is required')
    end
  end

  describe '#lookup' do
    subject(:provider) { described_class.new(access_key: access_key) }

    let(:access_key) { ENV.fetch('IPSTACK_ACCESS_KEY', 'test_key') }

    it 'maps a successful response into a provider result', vcr: { cassette_name: 'ipstack/valid_ip_lookup' } do
      result = provider.lookup('64.233.180.113')

      expect(result).to have_attributes(
        ip: '64.233.180.113',
        country_code: 'US',
        region_code: 'CA',
        city: 'Mountain View',
        zip: '94041'
      )

      expect(result.provider_response).to include(
        'continent_name' => 'North America',
        'connection' => include('isp' => 'Google')
      )
    end

    it 'supports a hostname query directly', vcr: { cassette_name: 'ipstack/google_hostname_lookup' } do
      result = provider.lookup('google.com')

      expect(result).to have_attributes(
        ip: '64.233.180.102',
        country_code: 'US',
        city: 'Mountain View'
      )
      expect(result.provider_response).to include(
        'connection' => include('isp' => 'Google')
      )
    end

    it 'raises InvalidIpError when the provider rejects the IP address' do
      stub_request(:get, /api\.ipstack\.com/)
        .to_return(
          status: 200,
          body: {
            success: false,
            error: { code: 106, info: 'The IP address supplied is invalid.' }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { provider.lookup('999.999.999.999') }.to raise_error(
        GeolocationProviders::InvalidIpError,
        'The IP address supplied is invalid.'
      )
    end

    it 'raises QuotaError when the provider quota is exceeded' do
      stub_request(:get, /api\.ipstack\.com/)
        .to_return(
          status: 200,
          body: {
            success: false,
            error: { code: 104, info: 'Monthly request volume limit reached.' }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { provider.lookup('1.1.1.1') }.to raise_error(
        GeolocationProviders::QuotaError,
        'Monthly request volume limit reached.'
      )
    end

    it 'raises ProviderError for non-success HTTP responses' do
      stub_request(:get, /api\.ipstack\.com/).to_return(status: 500, body: '')

      expect { provider.lookup('1.1.1.1') }.to raise_error(
        GeolocationProviders::ProviderError,
        'Provider returned HTTP 500'
      )
    end

    it 'raises ProviderError for unknown provider error codes' do
      stub_request(:get, /api\.ipstack\.com/)
        .to_return(
          status: 200,
          body: {
            success: false,
            error: { code: 999, info: 'Unknown error.' }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { provider.lookup('1.1.1.1') }.to raise_error(
        GeolocationProviders::ProviderError,
        'Unknown error.'
      )
    end

    it 'maps timeout-style connection failures to TimeoutError' do
      stub_request(:get, /api\.ipstack\.com/).to_timeout

      expect { provider.lookup('1.1.1.1') }.to raise_error(
        GeolocationProviders::TimeoutError,
        'Provider request timed out'
      )
    end

    it 'wraps other Faraday errors as ProviderError' do
      allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::SSLError, 'SSL handshake failed')

      expect { provider.lookup('1.1.1.1') }.to raise_error(
        GeolocationProviders::ProviderError,
        /Provider HTTP error/
      )
    end
  end
end
# rubocop:enable Metrics/BlockLength
