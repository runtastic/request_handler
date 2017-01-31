# frozen_string_literal: true
require 'request_handler/schema_parser'
require 'request_handler/error'
module RequestHandler
  class BodyParser < SchemaParser
    def initialize(request:, schema:, schema_options: {})
      raise MissingArgumentError, "request.body": 'is missing' if request.body.nil?
      super(schema: schema, schema_options: schema_options)
      @request = request
    end

    def run
      validate_schema(flattened_request_body)
    end

    private

    def flattened_request_body
      body = request_body['data']
      body.merge!(body.delete('attributes') { {} })
      relationships = flatten_relationship_resource_linkages(body.delete('relationships') { {} })
      body.merge!(relationships)
      body
    end

    def flatten_relationship_resource_linkages(relationships)
      relationships.each_with_object({}) do |(k, v), memo|
        resource_linkage = v['data']
        next if resource_linkage.nil?
        memo[k] = resource_linkage
      end
    end

    def request_body
      b = request.body
      b.rewind
      b = b.read
      b.empty? ? {} : MultiJson.load(b)
    end

    attr_reader :request
  end
end
