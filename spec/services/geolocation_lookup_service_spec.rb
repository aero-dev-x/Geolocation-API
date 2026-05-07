# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe GeolocationLookupService do
  subject(:service) { described_class.new(provider: provider) }

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
      provider_response: {
        'ip' => '64.233.180.113',
        'connection' => { 'isp' => 'Google' }
      }
    )
  end

  before { allow(provider).to receive(:lookup).and_return(provider_result) }

  describe '#call' do
    it 'creates a geolocation using the resolved lookup data' do
      allow(GeolocationLookupResolver).to receive(:resolve).and_return(
        ip: '64.233.180.113',
        url: nil
      )

      expect do
        geolocation = service.call(input: { ip: '64.233.180.113', url: nil })

        expect(geolocation.ip).to eq('64.233.180.113')
        expect(geolocation.city).to eq('Mountain View')
        expect(geolocation.provider).to eq('null')
      end.to change(Geolocation, :count).by(1)
    end

    it 'persists the normalized URL when the resolver returns one' do
      allow(GeolocationLookupResolver).to receive(:resolve).and_return(
        ip: '64.233.180.113',
        url: 'https://google.com'
      )

      geolocation = service.call(input: { ip: nil, url: 'google.com' })

      expect(geolocation.url).to eq('https://google.com')
      expect(geolocation.ip).to eq('64.233.180.113')
      expect(geolocation.city).to eq('Mountain View')
    end

    it 'updates an existing record instead of creating a duplicate' do
      existing_record = create(:geolocation, ip: '64.233.180.113', city: 'Old City', provider: 'null')

      allow(GeolocationLookupResolver).to receive(:resolve).and_return(
        ip: '64.233.180.113',
        url: nil
      )

      expect do
        service.call(input: { ip: '64.233.180.113', url: nil })
      end.not_to change(Geolocation, :count)

      expect(existing_record.reload.city).to eq('Mountain View')
      expect(existing_record.provider_response).to eq(
        'ip' => '64.233.180.113',
        'connection' => { 'isp' => 'Google' }
      )
    end

    it 'reuses an existing IP record and fills the url when it was previously blank' do
      existing_record = create(
        :geolocation,
        ip: '64.233.180.113',
        url: nil,
        city: 'Old City',
        provider: 'null'
      )

      allow(GeolocationLookupResolver).to receive(:resolve).and_return(
        ip: '64.233.180.113',
        url: 'https://google.com'
      )

      expect do
        service.call(input: { ip: nil, url: 'google.com' })
      end.not_to change(Geolocation, :count)

      expect(existing_record.reload.url).to eq('https://google.com')
      expect(existing_record.city).to eq('Mountain View')
    end

    it 'propagates provider errors' do
      allow(GeolocationLookupResolver).to receive(:resolve).and_return(
        ip: '64.233.180.113',
        url: nil
      )
      allow(provider).to receive(:lookup).and_raise(GeolocationProviders::ProviderError, 'provider unavailable')

      expect do
        service.call(input: { ip: '64.233.180.113', url: nil })
      end.to raise_error(GeolocationProviders::ProviderError, 'provider unavailable')
    end
  end
end
# rubocop:enable Metrics/BlockLength
