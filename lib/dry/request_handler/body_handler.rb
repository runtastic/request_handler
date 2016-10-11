# frozen_string_literal: true
require "dry/request_handler/schema_handler"
module Dry
  module RequestHandler
    class BodyHandler < SchemaHandler
      def initialize(request:, schema:, schema_options: {})
        super(schema: schema, schema_options: schema_options)
        raise ArgumentError if request.nil? || request.body.nil?
        @request = request
      end

      def run
        validate_schema(flattened_request_body)
      end

      private

      def flattened_request_body
        body = request_body["data"]
        body.merge!(body.delete("attributes") { {} })
        relationships = flatten_relationship_resource_linkages(body.delete("relationships") { {} })
        body.merge!(relationships)
        body
      end

      def flatten_relationship_resource_linkages(relationships)
        relationships.each_with_object({}) do |(k, v), memo|
          resource_linkage = v["data"]
          next if resource_linkage.nil?
          memo[k] = resource_linkage
        end
      end

      def request_body # TODO: check if this is the best way to get the body -> Commonly used this way
        b = request.body
        b.rewind
        b = b.read
        b.empty? ? {} : MultiJson.load(b)
      end

      attr_reader :request
    end
  end
end
