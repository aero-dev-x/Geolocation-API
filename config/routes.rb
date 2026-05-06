# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :geolocations,
                param: :lookup_key,
                constraints: { lookup_key: %r{[^/]+} },
                only: %i[index create show destroy]
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
