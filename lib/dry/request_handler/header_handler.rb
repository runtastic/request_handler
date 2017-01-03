# frozen_string_literal: true
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class HeaderHandler
      def initialize(env:)
        raise MissingArgumentError.new(env: "is missing") if env.nil?
        @headers = Helper.deep_transform_keys_in_object(env.select { |k, _v| k.start_with?("HTTP_") }) do |k|
          k[5..-1].downcase.to_sym
        end
      end

      def run
        headers
      end

      private

      attr_reader :headers
    end
  end
end
