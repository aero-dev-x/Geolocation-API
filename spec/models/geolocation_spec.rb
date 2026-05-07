# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe Geolocation, type: :model do
  subject(:geolocation) { build(:geolocation) }

  it { is_expected.to validate_presence_of(:lookup_key) }
  it { is_expected.to validate_inclusion_of(:provider).in_array(described_class::PROVIDERS) }
  it { is_expected.to validate_uniqueness_of(:lookup_key).case_insensitive }

  it 'is valid with the factory defaults' do
    expect(geolocation).to be_valid
  end

  it 'requires either an IP address or a URL' do
    geolocation.ip = nil
    geolocation.url = nil

    expect(geolocation).not_to be_valid
    expect(geolocation.errors[:base]).to include('Either ip or url must be present')
  end

  it 'validates IP address format' do
    geolocation.ip = 'not-an-ip'

    expect(geolocation).not_to be_valid
    expect(geolocation.errors[:ip]).to include('must be a valid IP address')
  end

  it 'validates URL format when a URL is present' do
    geolocation.ip = nil
    geolocation.url = 'https:///'

    expect(geolocation).not_to be_valid
    expect(geolocation.errors[:url]).to include('must be valid')
  end

  it 'normalizes the lookup key before validation' do
    geolocation.lookup_key = '  HTTPS://Example.COM  '

    geolocation.validate

    expect(geolocation.lookup_key).to eq('https://example.com')
  end

  it 'validates latitude boundaries' do
    geolocation.latitude = 91

    expect(geolocation).not_to be_valid
    expect(geolocation.errors[:latitude]).to be_present
  end

  it 'validates longitude boundaries' do
    geolocation.longitude = 181

    expect(geolocation).not_to be_valid
    expect(geolocation.errors[:longitude]).to be_present
  end
end
# rubocop:enable Metrics/BlockLength
