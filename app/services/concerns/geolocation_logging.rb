# frozen_string_literal: true

module GeolocationLogging
  private

  def geolocation_log(message)
    return unless Rails.env.development?

    Rails.logger.info(message)
  end
end
