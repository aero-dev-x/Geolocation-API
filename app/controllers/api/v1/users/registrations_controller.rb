# frozen_string_literal: true

module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json
        skip_before_action :authenticate_user!

        def resource_name
          :user
        end

        private

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: {
              data: {
                id: resource.id.to_s,
                type: 'user',
                attributes: { email: resource.email }
              }
            }, status: :created
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
