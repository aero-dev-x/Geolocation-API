# frozen_string_literal: true

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('ALLOWED_ORIGINS', '*')

    resource '*',
             headers: :any,
             expose: ['Authorization'],
             methods: %i[get post put patch delete options head]
  end
end
