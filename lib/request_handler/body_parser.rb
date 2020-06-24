# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
require 'request_handler/document_parser'

module RequestHandler
  class BodyParser
    def initialize(request:, schema:, type: nil, schema_options: {})
      raise MissingArgumentError, "request.body": 'is missing' if request.body.nil?
      @request = request
      @schema = schema
      @schema_options = schema_options
      @type = type
    end

    def run
      DocumentParser.new(
        type:           type,
        document:       request_body,
        schema:         schema,
        schema_options: schema_options
      ).run
    end

    private

    def request_body
      b = request.body
      b.rewind
      b = b.read
      b.empty? ? {} : MultiJson.load(b)
    rescue MultiJson::ParseError => e
      raise ParseError, json: e.message
    end

    attr_reader :request, :schema, :schema_options, :type
  end
end
