# frozen_string_literal: true
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class SchemaHandler
      def initialize(schema:, schema_options: {})
        missing_arguments = []
        missing_arguments << "schema" if schema.nil?
        missing_arguments << "schema_options" if schema_options.nil?
        raise MissingArgumentError.new(missing_arguments) if missing_arguments.length.positive?
        raise WrongArgumentTypeError.new("schema")  unless schema.is_a?(Dry::Validation::Schema)
        @schema = schema
        @schema_options = schema_options
      end

      private

      def validate_schema(data)
        raise MissingArgumentError.new(["data"]) if data.nil?
        validator = schema.with(schema_options).call(data) # TODO: Check for performance impact
        raise SchemaValidationError if validator.failure?
        validator.output
      end

      attr_reader :schema, :schema_options
    end
  end
end
