# frozen_string_literal: true

module GeolocationProviders
  class NullProvider < ProviderBase
    def lookup(ip)
      Result.new(
        ip: ip,
        url: nil,
        country_name: 'Testland',
        country_code: 'TL',
        region_name: 'Test Region',
        region_code: 'TR',
        city: 'Test',
        zip: '00000',
        latitude: 0.0,
        longitude: 0.0,
        provider_response: { 'ip' => ip, 'provider' => 'null' }
      )
    end
  end
end
