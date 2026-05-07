# frozen_string_literal: true

module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        include AuthResponseRenderer

        respond_to :json
        skip_before_action :authenticate_user!

        def resource_name
          :user
        end

        private

        def respond_with(resource, _opts = {})
          render_auth_response(
            user: resource,
            access_token: request.env['warden-jwt_auth.token'],
            refresh_token: RefreshToken.issue_for!(resource),
            status: :ok
          )
        end

        def respond_to_on_destroy(**_opts)
          revoke_refresh_token!

          head :no_content
        end

        def revoke_refresh_token!
          refresh_token = params[:refresh_token]
          return if refresh_token.blank?

          RefreshToken.find_active_by_plaintext(refresh_token)&.revoke!
        end
      end
    end
  end
end
