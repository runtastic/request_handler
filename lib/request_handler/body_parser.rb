# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
require 'request_handler/json_api_data_parser'
module RequestHandler
  class BodyParser
    def initialize(request:, schema:, schema_options: {}, included_schemas: {})
      raise MissingArgumentError, "request.body": 'is missing' if request.body.nil?
      @request = request
      @schema = schema
      @schema_options = schema_options
      @included_schemas = included_schemas
    end

    def run
      JsonApiDataParser.new(
        data: request_body,
        schema: schema,
        schema_options: schema_options,
        included_schemas: included_schemas
      ).run
    end

    private

    def request_body
      b = request.body
      b.rewind
      b = b.read
      b.empty? ? {} : MultiJson.load(b)
    end

    attr_reader :request, :schema, :schema_options, :included_schemas
  end
end
