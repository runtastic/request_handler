# frozen_string_literal: true
module Dry
  module RequestHandler
    class AuthorizationHandler
      USER_ID_HEADER = "ACCEPT"
      APP_KEY_HEADER = "HTTP_AUTH"
      def initialize(env:)
        raise ArgumentError if env.nil?
        @headers = env.select { |k, _v| k.start_with?("HTTP_") }
      end

      def run
        {
          accept: accept,
          auth: auth
        }
      end

      private

      attr_reader :headers

      def accept
        headers.fetch(USER_ID_HEADER, nil)
      end

      def auth
        headers.fetch(APP_KEY_HEADER, nil)
      end
    end
  end
end
