# frozen_string_literal: true

class GeolocationSerializer
  include JSONAPI::Serializer

  set_type :geolocation

  attributes :ip,
             :url,
             :country_name,
             :country_code,
             :region_name,
             :region_code,
             :city,
             :zip,
             :latitude,
             :longitude,
             :provider,
             :created_at,
             :updated_at
end
