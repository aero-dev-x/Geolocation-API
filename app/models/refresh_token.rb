# frozen_string_literal: true

require 'digest'

class RefreshToken < ApplicationRecord
  TTL = 14.days

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where('expires_at > ?', Time.current) }

  def self.issue_for!(user)
    plaintext_token = SecureRandom.urlsafe_base64(48)

    create!(
      user: user,
      token_digest: digest(plaintext_token),
      expires_at: TTL.from_now
    )

    plaintext_token
  end

  def self.find_active_by_plaintext(token)
    return if token.blank?

    active.find_by(token_digest: digest(token))
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
