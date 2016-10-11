# frozen_string_literal: true
require "dry/request_handler/schema_handler"
module Dry
  module RequestHandler
    class FilterHandler < SchemaHandler
      def initialize(params:, schema:, additional_url_filter:, schema_options: {})
        @filter = params.fetch("filter") { {} }
        super(schema: schema, schema_options: schema_options)
        Array(additional_url_filter).each do |key|
          key = key.to_s
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
