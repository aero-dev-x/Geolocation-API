# frozen_string_literal: true

module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def auth_headers(user, password: 'Password1!')
    post '/api/v1/users/sign_in',
         params: { user: { email: user.email, password: password } },
         as: :json
    { 'Authorization' => response.headers['Authorization'] }
  end
end
