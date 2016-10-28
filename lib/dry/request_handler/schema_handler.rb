# frozen_string_literal: true
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class SchemaHandler
      def initialize(schema:, schema_options: {})
        missing_arguments = []
        missing_arguments << { schema: "is missing" } if schema.nil?
        missing_arguments << { schema_options: "is missing" } if schema_options.nil?
        raise MissingArgumentError.new(missing_arguments) if missing_arguments.length.positive?
        raise InternalArgumentError.new(schema: "must be a Schema")  unless schema.is_a?(Dry::Validation::Schema)
        @schema = schema
        @schema_options = schema_options
      end

      private

      def validate_schema(data)
        raise MissingArgumentError.new(data: "is missing") if data.nil?
        validator = validate(data)
        validation_failure?(validator)
        validator.output
      end

      def validate(data)
        if schema_options.empty?
          schema.call(data)
        else
          schema.with(schema_options).call(data)
        end
      end

      def validation_failure?(validator)
        if validator.failure?
          errors = validator.errors.each_with_object({}) do |(k, v), memo|
            memo[k] = v.join(" ")
          end
          raise SchemaValidationError.new(errors)
        end
      end

      attr_reader :schema, :schema_options
    end
  end
end
