# frozen_string_literal: true

class AuthTokenPairIssuer
  def initialize(user)
    @user = user
  end

  def call
    access_token, = Warden::JWTAuth::UserEncoder.new.call(@user, :user, nil)

    {
      access_token: access_token,
      refresh_token: RefreshToken.issue_for!(@user)
    }
  end
end
