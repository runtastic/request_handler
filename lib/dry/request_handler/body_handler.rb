# frozen_string_literal: true
require "dry/request_handler/schema_handler"
module Dry
  module RequestHandler
    class BodyHandler < SchemaHandler  # TODO: shared base with FilterHandler?
      def initialize(request:, schema:, schema_options: {})
        raise ArgumentError if request.nil? || request.body.nil?
        @request = request
        super(schema: schema, schema_options: schema_options)
      end

      def run
        super(flattened_request_body)
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

      def request_body # TODO: check if this is the best way to get the body
        b = request.body
        b.rewind
        b = b.read
        b.empty? ? {} : MultiJson.load(b)
      end

      attr_reader :request
    end
  end
end
