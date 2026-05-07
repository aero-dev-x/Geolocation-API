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

    it 'creates a user and returns a bearer token' do
      expect do
        post '/api/v1/users/sign_up', params: params, as: :json
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.headers['Authorization']).to start_with('Bearer ')
      expect(json_response.dig('data', 'attributes', 'email')).to eq('new@example.com')
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

    it 'returns the user payload and token for valid credentials' do
      post '/api/v1/users/sign_in',
           params: { user: { email: user.email, password: 'Password1!' } },
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers['Authorization']).to start_with('Bearer ')
      expect(json_response.dig('data', 'attributes', 'email')).to eq(user.email)
      expect(json_response.dig('data', 'attributes', 'token')).to be_present
      expect(response.headers['Authorization']).to eq("Bearer #{json_response.dig('data', 'attributes', 'token')}")
    end

    it 'returns unauthorized for invalid credentials' do
      post '/api/v1/users/sign_in',
           params: { user: { email: user.email, password: 'wrongpass' } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/users/sign_out' do
    let(:user) { create(:user) }

    it 'revokes the current token' do
      headers = auth_headers(user)

      delete '/api/v1/users/sign_out', headers: headers

      expect(response).to have_http_status(:no_content)

      get '/api/v1/geolocations', headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
# rubocop:enable Metrics/BlockLength
