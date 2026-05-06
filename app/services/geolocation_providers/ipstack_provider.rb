# frozen_string_literal: true

require 'faraday/retry'

module GeolocationProviders
  class IpstackProvider < ProviderBase
    BASE_URL = 'http://api.ipstack.com'

    def initialize(access_key: ENV.fetch('IPSTACK_ACCESS_KEY', nil), timeout: 5)
      raise ArgumentError, 'IPSTACK_ACCESS_KEY is required' if access_key.blank?

      @access_key = access_key
      @conn = Faraday.new(url: BASE_URL) do |f|
        f.options.timeout = timeout
        f.options.open_timeout = 3
        f.response :json
        f.request :retry, max: 2, interval: 0.5, retry_statuses: [429, 500, 502, 503, 504]
        f.adapter Faraday.default_adapter
      end
    end

    def lookup(ip)
      response = @conn.get("/#{ip}", access_key: @access_key, output: 'json')

      raise ProviderError, "Provider returned HTTP #{response.status}" unless response.success?

      body = response.body
      handle_error!(body) if body.is_a?(Hash) && body['error']

      build_result(body)
    rescue ProviderError, InvalidIpError, QuotaError
      raise
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed
      raise TimeoutError, 'Provider request timed out'
    rescue Faraday::Error => e
      raise ProviderError, "Provider HTTP error: #{e.message}"
    end

    private

    def build_result(body)
      Result.new(
        ip: body['ip'],
        url: nil,
        country_name: body['country_name'],
        country_code: body['country_code'],
        region_name: body['region_name'],
        region_code: body['region_code'],
        city: body['city'],
        zip: body['zip'],
        latitude: body['latitude'],
        longitude: body['longitude'],
        provider_response: body
      )
    end

    def handle_error!(body)
      code = body.dig('error', 'code')
      info = body.dig('error', 'info') || 'Unknown provider error'

      case code
      when 104, 105
        raise QuotaError, info
      when 106
        raise InvalidIpError, info
      else
        raise ProviderError, info
      end
    end
  end
end
