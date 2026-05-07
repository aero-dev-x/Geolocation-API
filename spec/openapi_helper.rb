# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('openapi').to_s
  config.openapi_format = :json

  config.openapi_specs = {
    'v1/openapi.json' => {
      openapi: '3.0.1',
      info: {
        title: 'Geolocations API',
        version: 'v1',
        description: 'API documentation for geolocation lookups and JWT-based authentication.'
      },
      servers: [
        {
          url: 'http://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'localhost:3000'
            }
          }
        }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        },
        schemas: {
          auth_user_attributes: {
            type: :object,
            properties: {
              email: { type: :string, format: :email },
              token: { type: :string, description: 'JWT access token. Expires after 30 minutes.' },
              refresh_token: { type: :string, description: 'Opaque refresh token used to rotate and obtain a new access token.' }
            },
            required: %w[email token refresh_token]
          },
          user_resource: {
            type: :object,
            properties: {
              id: { type: :string },
              type: { type: :string, enum: ['user'] },
              attributes: { '$ref' => '#/components/schemas/auth_user_attributes' }
            },
            required: %w[id type attributes]
          },
          user_response: {
            type: :object,
            properties: {
              data: { '$ref' => '#/components/schemas/user_resource' }
            },
            required: ['data']
          },
          sign_up_request: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  email: { type: :string, format: :email },
                  password: { type: :string },
                  password_confirmation: { type: :string, nullable: true }
                },
                required: %w[email password]
              }
            },
            required: ['user']
          },
          sign_in_request: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  email: { type: :string, format: :email },
                  password: { type: :string }
                },
                required: %w[email password]
              }
            },
            required: ['user']
          },
          refresh_token_request: {
            type: :object,
            properties: {
              refresh_token: { type: :string }
            },
            required: ['refresh_token']
          },
          optional_refresh_token_request: {
            type: :object,
            properties: {
              refresh_token: { type: :string, nullable: true }
            }
          },
          geolocation_attributes: {
            type: :object,
            properties: {
              ip: { type: :string, nullable: true },
              url: { type: :string, nullable: true },
              lookup_key: { type: :string },
              country_name: { type: :string, nullable: true },
              country_code: { type: :string, nullable: true },
              region_name: { type: :string, nullable: true },
              region_code: { type: :string, nullable: true },
              city: { type: :string, nullable: true },
              zip: { type: :string, nullable: true },
              latitude: { type: :string, nullable: true, description: 'Decimal latitude serialized as a string' },
              longitude: { type: :string, nullable: true, description: 'Decimal longitude serialized as a string' },
              provider: { type: :string },
              created_at: { type: :string, format: :'date-time' },
              updated_at: { type: :string, format: :'date-time' }
            },
            required: %w[
              lookup_key
              provider
              created_at
              updated_at
            ]
          },
          geolocation_resource: {
            type: :object,
            properties: {
              id: { type: :string },
              type: { type: :string, enum: ['geolocation'] },
              attributes: { '$ref' => '#/components/schemas/geolocation_attributes' }
            },
            required: %w[id type attributes]
          },
          geolocation_response: {
            type: :object,
            properties: {
              data: { '$ref' => '#/components/schemas/geolocation_resource' }
            },
            required: ['data']
          },
          geolocations_index_response: {
            type: :object,
            properties: {
              data: {
                type: :array,
                items: { '$ref' => '#/components/schemas/geolocation_resource' }
              },
              meta: {
                type: :object,
                properties: {
                  total_count: { type: :integer },
                  page: { type: :integer },
                  per_page: { type: :integer }
                },
                required: %w[total_count page per_page]
              }
            },
            required: %w[data meta]
          },
          geolocation_create_request: {
            type: :object,
            properties: {
              data: {
                type: :object,
                properties: {
                  type: { type: :string, enum: ['geolocations'] },
                  attributes: {
                    type: :object,
                    properties: {
                      ip: { type: :string, nullable: true },
                      url: { type: :string, nullable: true }
                    }
                  }
                },
                required: %w[type attributes]
              }
            },
            required: ['data']
          },
          error_object: {
            type: :object,
            properties: {
              status: { type: :string },
              code: { type: :string },
              title: { type: :string },
              detail: { type: :string }
            },
            required: %w[status code title detail]
          },
          error_response: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: { '$ref' => '#/components/schemas/error_object' }
              }
            },
            required: ['errors']
          }
        }
      },
      paths: {}
    }
  }
end
