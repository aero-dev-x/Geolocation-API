# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'POST /api/v1/users/sign_up' do
    let(:params) do
      {
        user: {
          email: 'new@example.com',
          password: 'Password1!',
          password_confirmation: 'Password1!'
        }
      }
    end

    it 'creates a user and returns access and refresh tokens' do
      expect do
        post '/api/v1/users/sign_up', params: params, as: :json
      end.to change(User, :count).by(1)
       .and change(RefreshToken, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.headers['Authorization']).to start_with('Bearer ')
      expect(json_response.dig('data', 'attributes', 'email')).to eq('new@example.com')
      expect(json_response.dig('data', 'attributes', 'token')).to be_present
      expect(json_response.dig('data', 'attributes', 'refresh_token')).to be_present
    end

    it 'returns validation errors for a duplicate email' do
      create(:user, email: 'new@example.com')

      post '/api/v1/users/sign_up', params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig('errors', 0, 'code')).to eq('validation_error')
      expect(json_response.dig('errors', 0, 'detail')).to include('email has already been taken')
    end

    it 'returns validation errors for a mismatched password confirmation' do
      post '/api/v1/users/sign_up',
           params: params.deep_merge(user: { password_confirmation: 'WrongPassword1!' }),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig('errors', 0, 'detail')).to include("password_confirmation doesn't match Password")
    end
  end

  describe 'POST /api/v1/users/sign_in' do
    let!(:user) { create(:user, email: 'login@example.com', password: 'Password1!') }

    it 'returns the user payload and access and refresh tokens for valid credentials' do
      post '/api/v1/users/sign_in',
           params: { user: { email: user.email, password: 'Password1!' } },
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers['Authorization']).to start_with('Bearer ')
      expect(json_response.dig('data', 'attributes', 'email')).to eq(user.email)
      expect(json_response.dig('data', 'attributes', 'token')).to be_present
      expect(json_response.dig('data', 'attributes', 'refresh_token')).to be_present
      expect(response.headers['Authorization']).to eq("Bearer #{json_response.dig('data', 'attributes', 'token')}")
    end

    it 'returns unauthorized for invalid credentials' do
      post '/api/v1/users/sign_in',
           params: { user: { email: user.email, password: 'wrongpass' } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/users/refresh_token' do
    let!(:user) { create(:user, email: 'refresh@example.com', password: 'Password1!') }

    it 'rotates the refresh token and returns a new access token' do
      post '/api/v1/users/sign_in',
           params: { user: { email: user.email, password: 'Password1!' } },
           as: :json

      old_refresh_token = json_response.dig('data', 'attributes', 'refresh_token')

      expect do
        post '/api/v1/users/refresh_token',
             params: { refresh_token: old_refresh_token },
             as: :json
      end.not_to change(User, :count)

      expect(response).to have_http_status(:ok)
      expect(response.headers['Authorization']).to start_with('Bearer ')
      expect(json_response.dig('data', 'attributes', 'email')).to eq(user.email)
      expect(json_response.dig('data', 'attributes', 'token')).to be_present
      expect(json_response.dig('data', 'attributes', 'refresh_token')).to be_present
      expect(json_response.dig('data', 'attributes', 'refresh_token')).not_to eq(old_refresh_token)
      expect(response.headers['Authorization']).to eq("Bearer #{json_response.dig('data', 'attributes', 'token')}")
      expect(RefreshToken.active.count).to eq(1)
    end

    it 'rejects a reused refresh token after rotation' do
      post '/api/v1/users/sign_in',
           params: { user: { email: user.email, password: 'Password1!' } },
           as: :json

      refresh_token = json_response.dig('data', 'attributes', 'refresh_token')

      post '/api/v1/users/refresh_token', params: { refresh_token: refresh_token }, as: :json
      post '/api/v1/users/refresh_token', params: { refresh_token: refresh_token }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response.dig('errors', 0, 'code')).to eq('invalid_refresh_token')
    end

    it 'rejects an invalid refresh token' do
      post '/api/v1/users/refresh_token',
           params: { refresh_token: 'invalid-token' },
           as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response.dig('errors', 0, 'code')).to eq('invalid_refresh_token')
    end

    it 'returns a bad request when the refresh token is missing' do
      post '/api/v1/users/refresh_token', params: {}, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json_response.dig('errors', 0, 'code')).to eq('missing_parameter')
    end
  end

  describe 'DELETE /api/v1/users/sign_out' do
    let(:user) { create(:user) }

    it 'revokes the current token' do
      post '/api/v1/users/sign_in',
           params: { user: { email: user.email, password: 'Password1!' } },
           as: :json

      headers = { 'Authorization' => response.headers['Authorization'] }
      refresh_token = json_response.dig('data', 'attributes', 'refresh_token')

      delete '/api/v1/users/sign_out',
             params: { refresh_token: refresh_token },
             headers: headers,
             as: :json

      expect(response).to have_http_status(:no_content)

      get '/api/v1/geolocations', headers: headers
      expect(response).to have_http_status(:unauthorized)

      post '/api/v1/users/refresh_token',
           params: { refresh_token: refresh_token },
           as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
# rubocop:enable Metrics/BlockLength
