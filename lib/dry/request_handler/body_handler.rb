# frozen_string_literal: true
require "dry/request_handler/schema_handler"
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class BodyHandler < SchemaHandler
      def initialize(request:, schema:, schema_options: {})
        raise MissingArgumentError.new(["request"]) if request.nil?
        raise MissingArgumentError.new(["reques.body"]) if request.body.nil?
        super(schema: schema, schema_options: schema_options)
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

      def request_body
        b = request.body
        b.rewind
        b = b.read
        b.empty? ? {} : MultiJson.load(b)
      end

      attr_reader :request
    end
  end
end
