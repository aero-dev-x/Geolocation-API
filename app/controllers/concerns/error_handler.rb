# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    # Rails checks rescue handlers in reverse order.
    # Keep StandardError first so specific handlers below take priority.
    rescue_from StandardError, with: :handle_internal_error

    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from ActionController::ParameterMissing, with: :handle_missing_parameter
    rescue_from AmbiguousParameterError, with: :handle_ambiguous_parameter
    rescue_from InvalidUrlError, with: :handle_invalid_url

    rescue_from GeolocationProviders::ProviderError, with: :handle_provider_error
    rescue_from GeolocationProviders::InvalidIpError, with: :handle_invalid_ip
    rescue_from GeolocationProviders::DnsError, with: :handle_dns_error
    rescue_from GeolocationProviders::QuotaError, with: :handle_quota_error
    rescue_from GeolocationProviders::TimeoutError, with: :handle_provider_timeout
  end

  private

  def render_error(status:, code:, title:, detail:)
    render json: {
      errors: [
        {
          status: Rack::Utils.status_code(status).to_s,
          code: code,
          title: title,
          detail: detail
        }
      ]
    }, status: status
  end

  def handle_not_found(error)
    render_error(
      status: :not_found,
      code: 'not_found',
      title: 'Resource Not Found',
      detail: error.message
    )
  end

  def handle_validation_error(error)
    render_error(
      status: :unprocessable_entity,
      code: 'validation_error',
      title: 'Validation Error',
      detail: error.record.errors.full_messages.join(', ')
    )
  end

  def handle_missing_parameter(error)
    render_error(
      status: :bad_request,
      code: 'missing_parameter',
      title: 'Missing Parameter',
      detail: error.message
    )
  end

  def handle_ambiguous_parameter(error)
    render_error(
      status: :bad_request,
      code: 'ambiguous_parameter',
      title: 'Ambiguous Parameter',
      detail: error.message
    )
  end

  def handle_invalid_url(error)
    render_error(
      status: :unprocessable_entity,
      code: 'invalid_url',
      title: 'Invalid URL',
      detail: error.message
    )
  end

  def handle_invalid_ip(error)
    render_error(
      status: :unprocessable_entity,
      code: 'invalid_ip',
      title: 'Invalid IP Address',
      detail: error.message
    )
  end

  def handle_dns_error(error)
    render_error(
      status: :unprocessable_entity,
      code: 'dns_resolution_failed',
      title: 'DNS Resolution Failed',
      detail: error.message
    )
  end

  def handle_quota_error(error)
    render_error(
      status: :too_many_requests,
      code: 'quota_exceeded',
      title: 'Provider Quota Exceeded',
      detail: error.message
    )
  end

  def handle_provider_timeout(error)
    render_error(
      status: :gateway_timeout,
      code: 'provider_timeout',
      title: 'Provider Timeout',
      detail: error.message
    )
  end

  def handle_provider_error(error)
    render_error(
      status: :bad_gateway,
      code: 'provider_error',
      title: 'Provider Error',
      detail: error.message
    )
  end

  def handle_internal_error(error)
    Rails.logger.error("[ErrorHandler] #{error.class}: #{error.message}")
    Rails.logger.error(error.backtrace&.first(10)&.join("\n"))

    render_error(
      status: :internal_server_error,
      code: 'internal_error',
      title: 'Internal Server Error',
      detail: 'An unexpected error occurred'
    )
  end
end
