# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  root to: redirect('/api-docs')

  scope path: '/api/v1' do
    devise_for :users,
               path: '',
               path_names: {
                 sign_in: 'users/sign_in',
                 sign_out: 'users/sign_out',
                 registration: 'users/sign_up'
               },
               controllers: {
                 sessions: 'api/v1/users/sessions',
                 registrations: 'api/v1/users/registrations'
               }

    post 'users/refresh_token', to: 'api/v1/users/refresh_tokens#create'
  end

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
