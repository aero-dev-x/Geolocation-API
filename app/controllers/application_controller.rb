# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ErrorHandler

  private

  def render_jsonapi(resource, serializer:, status: :ok, meta: nil)
    options = {}
    options[:meta] = meta if meta.present?

    render json: serializer.new(resource, options).serializable_hash, status: status
  end
end
