# frozen_string_literal: true

module Api
  module V1
    module Users
      class RefreshTokensController < ApplicationController
        include AuthResponseRenderer

        skip_before_action :authenticate_user!

        def create
          token_pair = RefreshTokenExchange.new.call(refresh_token: refresh_token_param)

          render_auth_response(
            user: token_pair[:user],
            access_token: token_pair[:access_token],
            refresh_token: token_pair[:refresh_token],
            status: :ok
          )
        end

        private

        def refresh_token_param
          params.require(:refresh_token)
        end
      end
    end
  end
end
