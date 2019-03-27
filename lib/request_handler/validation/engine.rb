
require_relative 'errors'

module RequestHandler
  module Validation
    class Engine
      def self.valid_schema?(_schema)
        raise NotImplementedError
      end

      def self.validate(_value, _schema, options: {}) # rubocop:disable Lint/UnusedMethodArgument
        raise NotImplementedError
      end

      def self.validate!(_value, _schema, options: {}) # rubocop:disable Lint/UnusedMethodArgument
        raise NotImplementedError
      end

      private

      attr_accessor :value, :schema, :options
    end
  end
end
