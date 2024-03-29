# frozen_string_literal: true

require "request_handler/schema_parser"
require "request_handler/error"
module RequestHandler
  class JsonApiDocumentParser < SchemaParser
    NON_ATTRIBUTE_MEMBERS = %i[id type meta links].freeze
    # SEE: https://jsonapi.org/format/1.0/#document-resource-objects
    VALID_DATA_MEMBERS = %w[id type attributes relationships links meta].freeze

    def initialize(document:, schema:, schema_options: {})
      raise MissingArgumentError.new(data: "is missing") if document.nil?

      super(schema: schema, schema_options: schema_options)
      @document = document
    end

    def run
      resource = flattened_document
      validate_schema(resource)
    end

    private

    def flattened_document
      resource = document.fetch("data") do
        raise BodyParamsError.new([{ code:   "INVALID_JSON_API",
                                     status: "400",
                                     title:  "Body is not a valid JSON API payload",
                                     detail: "Member 'data' is missing",
                                     source: { pointer: "/" } }])
      end
      validate_json_api_data_members(resource)
      flatten_resource!(resource)
    end

    def validate_json_api_data_members(data)
      data.each_key do |k|
        next if VALID_DATA_MEMBERS.include?(k)

        raise BodyParamsError.new([{ code:   "INVALID_JSON_API",
                                     status: "400",
                                     title:  "Body is not a valid JSON API payload",
                                     detail: "Member 'data' contains invalid member!",
                                     source: { pointer: "/data/#{k}" } }])
      end
    end

    def flatten_resource!(resource)
      resource.merge!(resource.delete("attributes") { {} })
      relationships = flatten_relationship_resource_linkages(resource.delete("relationships") { {} })
      resource.merge!(relationships)
    end

    def flatten_relationship_resource_linkages(relationships)
      relationships.each_with_object({}) do |(k, v), memo|
        resource_linkage = v["data"]
        memo[k] = resource_linkage
      end
    end

    def build_pointer(error)
      non_nested_identifier = error[:schema_pointer] == error[:element].to_s
      non_attribute_member = NON_ATTRIBUTE_MEMBERS.include?(error[:element])
      ["/data",
       ("attributes" unless non_attribute_member && non_nested_identifier),
       error[:schema_pointer]].compact.join("/")
    end

    attr_reader :document
  end
end
