# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe GeolocationLookupResolver do
  describe '.resolve' do
    it 'returns the IP lookup payload when given an IP address' do
      expect(described_class.resolve(ip: '1.2.3.4', url: nil)).to eq(
        ip: '1.2.3.4',
        url: nil,
        lookup_key: '1.2.3.4'
      )
    end

    it 'normalizes a bare hostname into an https URL' do
      allow(Resolv).to receive(:getaddress).with('google.com').and_return('64.233.180.113')

      expect(described_class.resolve(ip: nil, url: 'google.com')).to eq(
        ip: '64.233.180.113',
        url: 'https://google.com',
        lookup_key: 'https://google.com'
      )
    end

    it 'raises a missing parameter error when both values are blank' do
      expect do
        described_class.resolve(ip: nil, url: nil)
      end.to raise_error(ActionController::ParameterMissing, 'param is missing or the value is empty: ip or url')
    end

    it 'raises an ambiguous parameter error when both values are present' do
      expect do
        described_class.resolve(ip: '1.2.3.4', url: 'https://example.com')
      end.to raise_error(AmbiguousParameterError, 'Provide exactly one of ip or url, not both')
    end

    it 'raises InvalidIpError for an invalid IP address' do
      expect do
        described_class.resolve(ip: '999.999.999.999', url: nil)
      end.to raise_error(GeolocationProviders::InvalidIpError, 'Invalid IP address')
    end

    it 'raises InvalidUrlError for a malformed URL' do
      expect do
        described_class.resolve(ip: nil, url: 'https:///')
      end.to raise_error(InvalidUrlError, 'Invalid URL')
    end

    it 'raises DnsError when the hostname cannot be resolved' do
      allow(Resolv).to receive(:getaddress).with('missing.example').and_raise(Resolv::ResolvError)

      expect do
        described_class.resolve(ip: nil, url: 'missing.example')
      end.to raise_error(GeolocationProviders::DnsError, 'Could not resolve host')
    end
  end
end
# rubocop:enable Metrics/BlockLength
