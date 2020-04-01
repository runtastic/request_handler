# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'

module RequestHandler
  class HeaderParser < SchemaParser
    def initialize(env:, schema: nil, schema_options: {})
      super(schema: schema, schema_options: schema_options) unless schema.nil?

      raise MissingArgumentError, env: 'is missing' if env.nil?
      @headers = Helper.deep_transform_keys_in_object(env.select { |k, _v| k.start_with?('HTTP_') }) do |k|
        k[5..-1].downcase.to_sym
      end
    end

    def run
      return headers if schema.nil?

      validate_headers!
    end

    private

    def validate_headers!
      validate_schema(headers)
    rescue SchemaValidationError => e
      raise ExternalArgumentError, external_argument_error_params(e)
    end

    def external_argument_error_params(error)
      error.errors.map do |schema_error|
        header = schema_error[:source][:pointer]
        {
          status: '400',
          code: "#{headers[header.to_sym] ? 'INVALID' : 'MISSING'}_HEADER",
          detail: "#{format_header_name(header)} #{schema_error[:detail]}"
        }
      end
    end

    def format_header_name(name)
      name.split('_').map(&:capitalize).join('-')
    end

    attr_reader :headers
  end
end
