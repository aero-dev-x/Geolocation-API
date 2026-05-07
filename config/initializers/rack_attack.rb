# frozen_string_literal: true

module Rack
  class Attack
    # General API throttle
    throttle('api/ip', limit: 300, period: 5.minutes) do |req|
      req.ip if req.path.start_with?('/api/')
    end

    # Login throttle (brute force protection)
    throttle('logins/ip', limit: 10, period: 1.minute) do |req|
      req.ip if req.path.start_with?('/api/v1/users/sign_in') && req.post?
    end

    self.throttled_responder = lambda do |req|
      match_data = req.env['rack.attack.match_data']
      now        = match_data[:epoch_time]

      retry_after = match_data[:period] - (now % match_data[:period])

      body = JSON.generate(
        errors: [{
          status: '429',
          code: 'rate_limit_exceeded',
          title: 'Too Many Requests',
          detail: "Rate limit exceeded. Please retry after #{retry_after} seconds."
        }]
      )

      headers = {
        'Content-Type' => 'application/vnd.api+json',
        'Content-Length' => body.bytesize.to_s,
        'Retry-After' => retry_after.to_s
      }

      [429, headers, [body]]
    end
  end
end
