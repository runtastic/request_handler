require_relative 'errors'
require_relative 'engine'
require_relative 'result'
require 'active_support/core_ext/hash/keys'

module RequestHandler
  module Validation
    class DryEngine < Engine
      def self.valid_schema?(schema)
        schema.respond_to?(:call)
      end

      def self.validate(value, schema, options: {})
        value = value.deep_symbolize_keys if schema.respond_to?(:rules) &&
                                             schema.rules.keys.first.is_a?(Symbol)
        result = if options.empty?
                   schema.call(value)
                 else
                   schema.with(options).call(value)
                 end

        to_result(result)
      rescue Dry::Types::ConstraintError => e
        Result.new(output: nil, errors: { '' => e })
      end

      def self.validate!(value, schema, options: {})
        validate(value, schema, options).tap do |result|
          raise Validation::Error unless result.valid?
        end
      end

      def self.to_result(result)
        if result.is_a?(Dry::Validation::Result)
          Result.new(output: result.output, errors: result.errors)
        else
          Result.new(output: result, errors: {})
        end
      end
    end
  end
end
