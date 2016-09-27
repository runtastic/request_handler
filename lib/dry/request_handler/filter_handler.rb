# frozen_string_literal: true
module Dry
  module RequestHandler
    class FilterHandler
      def initialize(params:, schema:, additional_url_filter:, schema_options: {})
        @filter = params.fetch("filter") { {} }
        @schema = schema
        @schema_options = schema_options
        Array(additional_url_filter).each do |key|
          key = key.to_s
          @filter[key] = params.fetch(key)
        end
      end

      def run
        validator = schema.with(schema_options).call(filter)
        raise "schema error" if validator.failure? # TODO: proper error
        validator.output
      end

      private

      attr_reader :filter, :schema, :schema_options
    end
  end
end
