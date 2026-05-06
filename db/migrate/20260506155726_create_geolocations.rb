# frozen_string_literal: true

class CreateGeolocations < ActiveRecord::Migration[7.1]
  def change
    create_table :geolocations do |t|
      t.string :lookup_key, null: false
      t.string :ip
      t.text :url
      t.string :country_name
      t.string :country_code, limit: 2
      t.string :region_name
      t.string :region_code
      t.string :city
      t.string :zip
      t.decimal :latitude,  precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :provider, null: false, default: "ipstack"
      t.jsonb :provider_response, default: {}

      t.timestamps
    end

    add_index :geolocations, :lookup_key, unique: true
    add_index :geolocations, :ip
    add_index :geolocations, :provider_response, using: :gin
  end
end
