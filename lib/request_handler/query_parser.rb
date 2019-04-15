# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
module RequestHandler
  class QueryParser < SchemaParser
    RESERVED_KEYS = %w[fields filter include page sort].freeze

    def initialize(params:, schema:, schema_options: {})
      super(schema: schema, schema_options: schema_options)
      @query = params.dup
      RESERVED_KEYS.each { |key| query.delete(key) }
    end

    def run
      validate_schema(query)
    rescue SchemaValidationError => e
      raise ExternalArgumentError, (e.errors.map do |schema_error|
        param = schema_error[:source][:pointer]
        { status: '400',
          code: "#{query[param] ? 'INVALID' : 'MISSING'}_QUERY_PARAMETER",
          detail: schema_error[:detail],
          source: { param: param } }
      end)
    end

    private

    attr_reader :query
  end
end
