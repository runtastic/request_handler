# frozen_string_literal: true
module Dry
  module RequestHandler
    class BaseError < StandardError
      attr_reader :errors
      def initialize(errors)
        @errors = errors
        super(message)
      end
      def message
        @errors.each_with_object("") do |(key, value), memo|
          memo+=key.to_s+": "+value.to_s+", "
        end
      end
    end
    class MissingArgumentError < BaseError
    end
    class WrongArgumentTypeError < BaseError
    end
    class InvalidArgumentError < BaseError
    end
    class SchemaValidationError < BaseError
    end
    class OptionNotAllowedError < BaseError
    end
    class NoConfigAvailableError < BaseError
    end
  end
end
