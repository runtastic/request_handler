# frozen_string_literal: true
module Dry
  module RequestHandler
    class AuthorizationHandler
      def initialize(env:)
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
        # TODO: move string into constant
        headers.fetch("ACCEPT", nil)
      end

      def auth
        # TODO: move string into constant
        headers.fetch("HTTP_AUTH", nil)
      end
    end
  end
end
