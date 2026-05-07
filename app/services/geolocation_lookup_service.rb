# frozen_string_literal: true

class GeolocationLookupService
  include GeolocationLogging

  def initialize(provider: Rails.configuration.geolocation_provider)
    @provider = provider.respond_to?(:lookup) ? provider : provider.new
  end

  def call(input:)
    geolocation_log("[GeolocationLookupService] start input=#{input.compact.inspect} provider=#{@provider.class.name}")

    resolved = GeolocationLookupResolver.resolve(
      ip: input[:ip],
      url: input[:url]
    )

    geolocation_log("[GeolocationLookupService] resolved ip=#{resolved[:ip].inspect} url=#{resolved[:url].inspect}")

    result = @provider.lookup(resolved[:ip])

    geolocation = find_existing_geolocation(result: result) || Geolocation.new
    geolocation.url = resolved[:url] if geolocation.url.blank? && resolved[:url].present?

    geolocation.update!(
      ip: result.ip,
      url: geolocation.url,
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

    geolocation_log("[GeolocationLookupService] persisted geolocation id=#{geolocation.id} ip=#{geolocation.ip.inspect} url=#{geolocation.url.inspect} provider=#{provider_name}")

    geolocation
  end

  private

  def provider_name
    @provider.class.name.demodulize.underscore.delete_suffix('_provider')
  end

  def find_existing_geolocation(result:)
    by_ip = Geolocation.find_by(ip: result.ip)
    geolocation_log("[GeolocationLookupService] matched existing record by ip=#{result.ip.inspect} id=#{by_ip.id}") if by_ip
    by_ip
  end
end
