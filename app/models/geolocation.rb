# frozen_string_literal: true

require 'uri'
require 'ipaddr'

class Geolocation < ApplicationRecord
  PROVIDERS = %w[ipstack null].freeze

  validates :ip, presence: true, uniqueness: true
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

  def url_must_be_valid
    return if url.blank?

    uri = URI.parse(url)
    if uri.host.blank?
      errors.add(:url, 'must be valid')
      return
    end

    IPAddr.new(uri.host)
    errors.add(:url, 'must be a hostname or website URL, not an IP address')
  rescue URI::InvalidURIError
    errors.add(:url, 'must be valid')
  rescue IPAddr::InvalidAddressError
    nil
  end
end
