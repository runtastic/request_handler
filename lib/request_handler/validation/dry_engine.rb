require_relative 'errors'
require_relative 'engine'
require_relative 'result'
require 'active_support/core_ext/hash/keys'

module RequestHandler
  module Validation
    class DryEngine < Engine
      def self.valid_schema?(schema)
        schema_instance?(schema) || schema_class?(schema)
      end

      def self.validate(value, schema, options: {})
        value = value.deep_symbolize_keys if value.is_a?(Hash)
        to_result(call_schema(value, schema, options))
      rescue Dry::Types::ConstraintError => e
        Result.new(output: nil, errors: { '' => e })
      end

      def self.call_schema(value, schema, options)
        if options.empty?
          schema_instance?(schema) ? schema.call(value) : schema.new.call(value)
        else
          schema_instance?(schema) ? schema.with(**options).call(value) : schema.new(**options).call(value)
        end
      end

      def self.schema_instance?(schema)
        schema.respond_to?(:call)
      end

      def self.schema_class?(schema)
        schema.respond_to?(:schema)
      end

      def self.validate!(value, schema, options: {})
        validate(value, schema, options: options).tap do |result|
          valid = result.respond_to?(:valid?) ? result.valid? : result.success?
          raise Validation::Error unless valid
        end
      end

      def self.to_result(result)
        output = result.respond_to?(:to_h) ? result.to_h : result
        errors = result.respond_to?(:errors) ? result.errors.to_h : {}
        Result.new(output: output, errors: errors)
      end

      def self.error_message(validation_error)
        validation_error
      end

      def self.error_pointer(_validation_error)
        nil
      end
    end
  end
end
