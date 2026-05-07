# frozen_string_literal: true

module AuthResponseRenderer
  private

  def render_auth_response(user:, access_token:, refresh_token:, status:)
    response.set_header('Authorization', "Bearer #{access_token}")

    render json: {
      data: {
        id: user.id.to_s,
        type: 'user',
        attributes: {
          email: user.email,
          token: access_token,
          refresh_token: refresh_token
        }
      }
    }, status: status
  end
end
