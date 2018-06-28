# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
module RequestHandler
  class JsonApiDocumentParser < SchemaParser
    def initialize(document:, schema:, schema_options: {})
      raise MissingArgumentError, "data": 'is missing' if document.nil?
      super(schema: schema, schema_options: schema_options)
      @document = document
    end

    def run
      resource = flattened_document
      validate_schema(resource)
    end

    private

    def flattened_document
      resource = document.fetch('data') do
        raise BodyParamsError, resource: 'must contain data'
      end
      flatten_resource!(resource)
    end

    def flatten_resource!(resource)
      resource.merge!(resource.delete('attributes') { {} })
      relationships = flatten_relationship_resource_linkages(resource.delete('relationships') { {} })
      resource.merge!(relationships)
    end

    def flatten_relationship_resource_linkages(relationships)
      relationships.each_with_object({}) do |(k, v), memo|
        resource_linkage = v['data']
        memo[k] = resource_linkage
      end
    end

    attr_reader :document
  end
end
