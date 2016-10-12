# frozen_string_literal: true
module Dry
  module RequestHandler
    class SchemaHandler
      def initialize(schema:, schema_options: {})
        if schema.nil? || schema_options.nil? || !schema.class.ancestors.include?(Dry::Validation::Schema)
          raise ArgumentError
        end
        @schema = schema
        @schema_options = schema_options
      end

      private

      def validate_schema(data)
        raise ArgumentError if data.nil?
        validator = schema.with(schema_options).call(data) # TODO: Check for performance impact
        raise "schema error" if validator.failure? # TODO: proper error
        validator.output
      end

      attr_reader :schema, :schema_options
    end
  end
end
