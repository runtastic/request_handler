# frozen_string_literal: true
module Dry
  module RequestHandler
    class BodyHandler # TODO: shared base with FilterHandler?
      def initialize(request:, schema:, schema_options: {})
        @request = request
        @schema = schema
        @schema_options = schema_options
      end

      def run
        validator = schema.with(schema_options).call(flattened_request_body)
        raise "schema error" if validator.failure? # TODO: proper error
        validator.output
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

      attr_reader :request, :schema, :schema_options
    end
  end
end
