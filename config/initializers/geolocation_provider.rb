# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rails.application.config.geolocation_provider =
    if Rails.env.test?
      GeolocationProviders::NullProvider.new
    elsif ENV['IPSTACK_ACCESS_KEY'].present?
      GeolocationProviders::IpstackProvider.new
    elsif Rails.env.production?
      raise 'IPSTACK_ACCESS_KEY must be set in production'
    else
      Rails.logger.warn '[GeolocationProvider] IPSTACK_ACCESS_KEY not set — using NullProvider (development only)'
      GeolocationProviders::NullProvider.new
    end
end
