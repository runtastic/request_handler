require_relative 'errors'
require_relative 'engine'
require_relative 'result'
require 'active_support/core_ext/hash/keys'

module RequestHandler
  module Validation
    class DefinitionEngine < Engine
      def self.valid_schema?(definition)
        definition.is_a?(::Definition::Types::Base)
      end

      def self.validate(value, schema, options: {}) # rubocop:disable Lint/UnusedMethodArgument
        value = value.deep_symbolize_keys if value.is_a?(Hash)
        result = schema.conform(value)
        Result.new(output: result.value, errors: result.error_hash)
      end

      def self.validate!(value, schema, options: {})
        validate(value, schema, options).tap do |result|
          valid = result.respond_to?(:valid?) ? result.valid? : result.success?
          raise Validation::Error unless valid
        end
      end

      def self.error_message(validation_error)
        validation_error.translated_error
      end

      def self.error_pointer(validation_error)
        validation_error.error_path.join('/')
      end
    end
  end
end
