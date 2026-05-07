# frozen_string_literal: true

module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        respond_to :json
        skip_before_action :authenticate_user!

        def resource_name
          :user
        end

        private

        def respond_with(resource, _opts = {})
          token = request.env['warden-jwt_auth.token']

          render json: {
            data: {
              id: resource.id.to_s,
              type: 'user',
              attributes: {
                email: resource.email,
                token: token
              }
            }
          }, status: :ok
        end

        def respond_to_on_destroy(**_opts)
          head :no_content
        end
      end
    end
  end
end
