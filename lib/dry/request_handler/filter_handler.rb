# frozen_string_literal: true
require "dry/request_handler/schema_handler"
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class FilterHandler < SchemaHandler
      def initialize(params:, schema:, additional_url_filter:, schema_options: {})
        @filter = params.fetch("filter") { {} }
        super(schema: schema, schema_options: schema_options)
        Array(additional_url_filter).each do |key|
          key = key.to_s
          raise Dry::RequestHandler::InvalidArgumentError
            .new("filter[" + key.to_s + "]", "the filter key was set twice") unless @filter[key].nil?
          @filter[key] = params.fetch(key)
        end
      end

      def run
        validate_schema(filter)
      end

      private

      attr_reader :filter
    end
  end
end
