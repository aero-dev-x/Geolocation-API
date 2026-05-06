# frozen_string_literal: true

require 'uri'
require 'ipaddr'

class Geolocation < ApplicationRecord
  PROVIDERS = %w[ipstack null].freeze

  validates :lookup_key, presence: true, uniqueness: { case_sensitive: false }
  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :latitude,
            numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 },
            allow_nil: true
  validates :longitude,
            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 },
            allow_nil: true
  validate :ip_or_url_present
  validate :ip_must_be_valid_address
  validate :url_must_be_valid

  before_validation :normalize_lookup_key

  private

  def ip_or_url_present
    return unless ip.blank? && url.blank?

    errors.add(:base, 'Either ip or url must be present')
  end

  def ip_must_be_valid_address
    return if ip.blank?

    IPAddr.new(ip)
  rescue IPAddr::InvalidAddressError
    errors.add(:ip, 'must be a valid IP address')
  end

  def normalize_lookup_key
    self.lookup_key = lookup_key.to_s.downcase.strip
  end

  def url_must_be_valid
    return if url.blank?

    uri = URI.parse(url)
    errors.add(:url, 'must be valid') unless uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:url, 'must be valid')
  end
end
