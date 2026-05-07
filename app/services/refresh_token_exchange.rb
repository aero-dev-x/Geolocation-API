# frozen_string_literal: true

class RefreshTokenExchange
  def call(refresh_token:)
    token_record = RefreshToken.find_active_by_plaintext(refresh_token)
    raise InvalidRefreshTokenError, 'Refresh token is invalid or expired' unless token_record

    RefreshToken.transaction do
      token_record.revoke!

      {
        user: token_record.user,
        **AuthTokenPairIssuer.new(token_record.user).call
      }
    end
  end
end
