# frozen_string_literal: true

module Api
  module V1
    class GeolocationsController < ApplicationController
      before_action :set_geolocation, only: %i[show destory]

      def index
        geolocations = Geolocation
                       .order(created_at: :desc)
                       .page(params.dig(:page, :number))
                       .per(params.dig(:page, :size) || 25)

        render_jsonapi(
          geolocations,
          serializer: GeolocationSerializer,
          meta: {
            total_count: geolocations.total_count,
            page: geolocations.current_page,
            per_page: geolocations.limit_value
          }
        )
      end

      def show
        render_jsonapi @geolocation, serializer: GeolocationSerializer
      end

      def create
        geolocation = GeolocationLookupService.new.call(input: geolocation_params)
        status = geolocation.previously_new_record? ? :created : :ok

        render_jsonapi geolocation, serializer: GeolocationSerializer, status: status
      end

      def destroy
        @geolocation.destroy!

        head :no_content
      end

      private

      def set_geolocation
        @geolocation = Geolocation.find_by!(lookup_key: CGI.unescape(params[:lookup_key]))
      end

      def geolocation_params
        attrs = params.require(:data).require(:attributes)

        ip = attrs[:ip]
        url = attrs[:url]

        raise ActionController::ParameterMissing, 'ip or url' if ip.blank? && url.blank?
        raise AmbiguousParameterError, 'Provide exactly one of ip or url, not both' if ip.present? && url.present?

        { ip: ip, url: url }
      end
    end
  end
end
