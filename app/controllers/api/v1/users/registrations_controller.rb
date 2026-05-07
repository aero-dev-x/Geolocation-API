# frozen_string_literal: true

module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        include AuthResponseRenderer

        respond_to :json
        skip_before_action :authenticate_user!

        def resource_name
          :user
        end

        private

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render_auth_response(
              user: resource,
              access_token: request.env['warden-jwt_auth.token'],
              refresh_token: RefreshToken.issue_for!(resource),
              status: :created
            )
          else
            render json: {
              errors: resource.errors.map do |error|
                { status: '422', code: 'validation_error',
                  title: 'Validation Error',
                  detail: "#{error.attribute} #{error.message}" }
              end
            }, status: :unprocessable_content
          end
        end
      end
    end
  end
end
