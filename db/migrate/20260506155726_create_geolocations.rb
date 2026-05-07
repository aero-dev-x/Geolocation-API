# frozen_string_literal: true

class CreateGeolocations < ActiveRecord::Migration[7.1]
  def change
    create_table :geolocations do |t|
      t.string :ip, null: false
      t.text :url
      t.string :country_name
      t.string :country_code, limit: 2
      t.string :region_name
      t.string :region_code
      t.string :city
      t.string :zip
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :provider, null: false, default: 'ipstack'
      t.jsonb :provider_response, null: false, default: {}

      t.timestamps
    end

    add_index :geolocations, :ip, unique: true
    add_index :geolocations, :url

    add_check_constraint :geolocations,
                         'latitude IS NULL OR latitude BETWEEN -90 AND 90',
                         name: 'latitude_range'

    add_check_constraint :geolocations,
                         'longitude IS NULL OR longitude BETWEEN -180 AND 180',
                         name: 'longitude_range'
  end
end
