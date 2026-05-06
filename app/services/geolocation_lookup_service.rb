# frozen_string_literal: true

class GeolocationLookupService
  def initialize(provider: Rails.configuration.geolocation_provider.new)
    @provider = provider
  end

  def call(input:)
    resolved = GeolocationLookupResolver.resolve(
      ip: input[:ip],
      url: input[:url]
    )

    result = @provider.lookup(resolved[:ip])

    geolocation = Geolocation.find_or_initialize_by(
      lookup_key: resolved[:lookup_key]
    )

    geolocation.update!(
      ip: result.ip,
      url: resolved[:url],
      country_name: result.country_name,
      country_code: result.country_code,
      region_name: result.region_name,
      region_code: result.region_code,
      city: result.city,
      zip: result.zip,
      latitude: result.latitude,
      longitude: result.longitude,
      provider: provider_name,
      provider_response: result.provider_response
    )

    geolocation
  end

  private

  def provider_name
    @provider.class.name.demodulize.underscore.delete_suffix('_provider')
  end
end
