# frozen_string_literal: true

require 'request_handler/error'
module RequestHandler
  class SchemaParser
    def initialize(schema:, schema_options: {})
      missing_arguments = []
      missing_arguments << { schema: 'is missing' } if schema.nil?
      missing_arguments << { schema_options: 'is missing' } if schema_options.nil?
      raise MissingArgumentError, missing_arguments unless missing_arguments.empty?
      raise InternalArgumentError, schema: 'must be a Schema' unless RequestHandler.engine.valid_schema?(schema)
      @schema = schema
      @schema_options = schema_options
    end

    private

    def validate_schema(data, with: schema)
      raise MissingArgumentError, data: 'is missing' if data.nil?
      validator = validate(data, schema: with)
      validation_failure?(validator)
      validator.output
    end

    def validate(data, schema:)
      RequestHandler.engine.validate(data, schema, options: schema_options)
    end

    def validation_failure?(validator)
      return if validator.valid?

      errors = build_errors(validator.errors).map do |error|
        jsonapi_error(error)
      end
      raise SchemaValidationError, errors
    end

    def build_errors(error_hash, path = [])
      errors = []
      error_hash.each do |k, v|
        errors += build_errors(v, path << k).flatten if v.is_a?(Hash)
        v.each { |error| errors << error(path, k, error) } if v.is_a?(Array)
        errors << error(path, k, v) if v.is_a?(String)
      end
      errors
    end

    def error(path, element, failure)
      schema_pointer = RequestHandler.engine.error_pointer(failure) || (path + [element]).join('/')
      {
        schema_pointer:  schema_pointer,
        element: element,
        message: RequestHandler.engine.error_message(failure)
      }
    end

    def jsonapi_error(error)
      {
        status: '422',
        code: 'INVALID_RESOURCE_SCHEMA',
        title: 'Invalid resource',
        detail: error[:message],
        source: { pointer: build_pointer(error) }
      }
    end

    def build_pointer(error)
      error[:schema_pointer]
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
