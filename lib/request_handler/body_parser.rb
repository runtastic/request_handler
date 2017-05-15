# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
module RequestHandler
  class BodyParser < SchemaParser
    def initialize(request:, schema:, schema_options: {}, included_schemas: {})
      raise MissingArgumentError, "request.body": 'is missing' if request.body.nil?
      super(schema: schema, schema_options: schema_options)
      @request = request
      @included_schemas = included_schemas
    end

    def run
      body, *included = flattened_request_body
      unless included_schemas?
        raise SchemaValidationError, included: 'must be empty' unless included.empty?
        return validate_schema(body)
      end

      validate_schemas(body, included)
    end

    private

    def flattened_request_body
      body = request_body.fetch('data') do
        raise ExternalArgumentError, body: 'must contain data'
      end
      [flatten_resource!(body), *parse_included]
    end

    def flatten_resource!(resource)
      resource.merge!(resource.delete('attributes') { {} })
      relationships = flatten_relationship_resource_linkages(resource.delete('relationships') { {} })
      resource.merge!(relationships)
    end

    def flatten_relationship_resource_linkages(relationships)
      relationships.each_with_object({}) do |(k, v), memo|
        resource_linkage = v['data']
        next if resource_linkage.nil?
        memo[k] = resource_linkage
      end
    end

    def parse_included
      included = request_body.fetch('included') { [] }
      included.each do |hsh|
        flatten_resource!(hsh)
      end
    end

    def request_body
      b = request.body
      b.rewind
      b = b.read
      b.empty? ? {} : MultiJson.load(b)
    end

    def included_schemas?
      !(included_schemas.nil? || included_schemas.empty?)
    end

    def validate_schemas(body, included)
      schemas = [validate_schema(body)]
      included_schemas.each do |type, schema|
        included.select { |inc| inc['type'] == type.to_s }.each do |inc|
          schemas << validate_schema(inc, with: schema)
        end
      end
      schemas
    end

    attr_reader :request, :included_schemas
  end
end
