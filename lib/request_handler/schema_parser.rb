# frozen_string_literal: true
require 'request_handler/error'
module RequestHandler
  class SchemaParser
    def initialize(schema:, schema_options: {})
      missing_arguments = []
      missing_arguments << { schema: 'is missing' } if schema.nil?
      missing_arguments << { schema_options: 'is missing' } if schema_options.nil?
      raise MissingArgumentError, missing_arguments unless missing_arguments.empty?
      raise InternalArgumentError, schema: 'must be a Schema' unless schema.is_a?(Dry::Validation::Schema)
      @schema = schema
      @schema_options = schema_options
    end

    private

    def validate_schema(data, with: schema)
      raise MissingArgumentError, data: 'is missing' if data.nil?
      validator = validate(data, with: with)
      validation_failure?(validator)
      validator.output
    end

    def validate(data, with:)
      if schema_options.empty?
        with.call(data)
      else
        with.with(schema_options).call(data)
      end
    end

    def validation_failure?(validator)
      return unless validator.failure?
      errors = validator.errors.each_with_object({}) do |(k, v), memo|
        add_note(v, k, memo)
      end
      raise SchemaValidationError, errors
    end

    def add_note(v, k, memo)
      memo[k] = if v.is_a? Array
                  v.join(' ')
                elsif v.is_a? Hash
                  v.each { |(val, key)| add_note(val, key, memo) }
                end
      memo
    end

    attr_reader :schema, :schema_options
  end
end
