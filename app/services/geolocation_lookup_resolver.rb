# frozen_string_literal: true

require_relative '../errors/api_errors'
require 'ipaddr'
require 'resolv'
require 'uri'

class GeolocationLookupResolver
  def self.resolve(ip:, url:)
    raise ActionController::ParameterMissing, 'ip or url' if ip.blank? && url.blank?
    raise AmbiguousParameterError, 'Provide exactly one of ip or url, not both' if ip.present? && url.present?

    if ip.present?
      validate_ip!(ip)

      {
        ip: ip,
        url: nil,
        lookup_key: ip
      }
    else
      normalized_url = normalize_url(url)
      host = extract_host!(normalized_url)
      resolved_ip = resolve_host!(host)

      {
        ip: resolved_ip,
        url: normalized_url,
        lookup_key: normalized_url
      }
    end
  end

  def self.validate_ip!(ip)
    IPAddr.new(ip)
  rescue IPAddr::InvalidAddressError
    raise GeolocationProviders::InvalidIpError, 'Invalid IP address'
  end

  def self.normalize_url(url)
    value = url.to_s.strip
    value.match?(%r{\Ahttps?://}) ? value : "https://#{value}"
  end

  def self.extract_host!(url)
    uri = URI.parse(url)
    raise InvalidUrlError, 'Invalid URL' if uri.host.blank?

    uri.host
  rescue URI::InvalidURIError
    raise InvalidUrlError, 'Invalid URL'
  end

  def self.resolve_host!(host)
    Resolv.getaddress(host)
  rescue Resolv::ResolvError
    raise GeolocationProviders::DnsError, 'Could not resolve host'
  end
end
