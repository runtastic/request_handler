# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
require 'request_handler/json_api_document_parser'
module RequestHandler
  class BodyParser
    def initialize(request:, schema:, schema_options: {})
      raise MissingArgumentError, "request.body": 'is missing' if request.body.nil?
      @request = request
      @schema = schema
      @schema_options = schema_options
    end

    def run
      parser = jsonapi? ? JsonApiDocumentParser : JsonParser
      parser.new(
        document: request_body,
        schema: schema,
        schema_options: schema_options
      ).run
    end

    private

    def jsonapi?
      request.env['Content-Type'] == 'application/vnd.api+json'
    end

    def request_body
      b = request.body
      b.rewind
      b = b.read
      b.empty? ? {} : MultiJson.load(b)
    end

    attr_reader :request, :schema, :schema_options
  end
end
