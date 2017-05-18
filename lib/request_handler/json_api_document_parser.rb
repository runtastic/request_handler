# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
module RequestHandler
  class JsonApiDocumentParser < SchemaParser
    def initialize(document:, schema:, schema_options: {}, included_schemas: {})
      raise MissingArgumentError, "data": 'is missing' if document.nil?
      super(schema: schema, schema_options: schema_options)
      @document = document
      @included_schemas = included_schemas
    end

    def run
      resource, *included = flattened_document
      unless included_schemas?
        raise SchemaValidationError, included: 'must be empty' unless included.empty?
        return validate_schema(resource)
      end

      validate_schemas(resource, included)
    end

    private

    def flattened_document
      resource = document.fetch('data') do
        raise ExternalArgumentError, resource: 'must contain data'
      end
      [flatten_resource!(resource), *parse_included]
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
      included = document.fetch('included') { [] }
      included.each do |hsh|
        flatten_resource!(hsh)
      end
    end

    def included_schemas?
      !(included_schemas.nil? || included_schemas.empty?)
    end

    def validate_schemas(resource, included)
      schemas = [validate_schema(resource)]
      included_schemas.each do |type, schema|
        included.select { |inc| inc['type'] == type.to_s }.each do |inc|
          schemas << validate_schema(inc, with: schema)
        end
      end
      schemas
    end

    attr_reader :document, :included_schemas
  end
end
