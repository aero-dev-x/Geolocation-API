# frozen_string_literal: true

module GeolocationProviders
  class ProviderBase
    def lookup(ip)
      raise NotImplementedError, "#{self.class}#lookup is not implemented"
    end
  end

  Result = Data.define(
    :ip,
    :url,
    :country_name,
    :country_code,
    :region_name,
    :region_code,
    :city,
    :zip,
    :latitude,
    :longitude,
    :provider_response
  )

  class ProviderError < StandardError; end
  class InvalidIpError < StandardError; end
  class QuotaError < ProviderError; end
  class TimeoutError < ProviderError; end
  class DnsError < StandardError; end
end
