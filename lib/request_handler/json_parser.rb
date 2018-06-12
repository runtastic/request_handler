# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
module RequestHandler
  class JsonParser < SchemaParser
    def initialize(document:, schema:, schema_options: {})
      raise MissingArgumentError, "json": 'no content sent in document' if document.nil?
      super(schema: schema, schema_options: schema_options)
      @document = document
    end

    def run
      validate_schema(document)
    end

    attr_reader :document
  end
end
