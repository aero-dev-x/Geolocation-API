# frozen_string_literal: true

class ApiUnauthorizedResponder
  BODY = JSON.generate(
    errors: [{
      status: '401',
      code: 'unauthorized',
      title: 'Unauthorized',
      detail: 'You need to sign in or sign up before continuing.'
    }]
  ).freeze

  def self.call(_env)
    [401, { 'Content-Type' => 'application/json', 'Content-Length' => BODY.bytesize.to_s }, [BODY]]
  end
end
