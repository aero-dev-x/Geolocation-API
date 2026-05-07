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
        url: nil
      }
    else
      normalized_url = normalize_url(url)
      dev_log("[GeolocationLookupResolver] normalized url=#{url.inspect} -> #{normalized_url.inspect}")
      host = extract_host!(normalized_url)
      resolved_ip = resolve_host!(host)

      {
        ip: resolved_ip,
        url: normalized_url
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
    raise InvalidUrlError, 'Use the ip field for IP address lookups' if ip_address?(uri.host)

    uri.host
  rescue URI::InvalidURIError
    raise InvalidUrlError, 'Invalid URL'
  end

  def self.resolve_host!(host)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    dev_log("[GeolocationLookupResolver] resolving host=#{host.inspect}")
    resolved_ip = Resolv.getaddress(host)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    dev_log("[GeolocationLookupResolver] resolved host=#{host.inspect} ip=#{resolved_ip.inspect} duration_ms=#{duration_ms}")
    resolved_ip
  rescue Resolv::ResolvError
    dev_log("[GeolocationLookupResolver] dns resolution failed host=#{host.inspect}")
    raise GeolocationProviders::DnsError, 'Could not resolve host'
  end

  def self.dev_log(message)
    return unless Rails.env.development?

    Rails.logger.info(message)
  end

  def self.ip_address?(value)
    IPAddr.new(value)
    true
  rescue IPAddr::InvalidAddressError
    false
  end
end
