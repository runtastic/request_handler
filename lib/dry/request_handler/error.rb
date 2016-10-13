# frozen_string_literal: true
module Dry
  module RequestHandler
    class MissingArgumentError < StandardError
      def initialize(arguments)
        @arguments = arguments
        super(message)
      end

      def message
        "The arguments #{@arguments} are missing."
      end
    end
    class WrongArgumentTypeError < StandardError
      def initialize(argument)
        super("The argument #{argument} has the wrong type")
      end
    end
    class InvalidArgumentError < StandardError
      def initialize(argument, message = nil)
        super("The argument #{argument} is invalid. (#{message || 'No further information given'})")
      end
    end
    class SchemaValidationError < StandardError
      def initialize(message = nil)
        super(message || "There was a validation error with the data passed to the schema.")
      end
    end
    class OptionNotAllowedError < StandardError
      def initialize(option)
        super("The option #{option} is not allowed.")
      end
    end
    class NoConfigAvailableError < StandardError
      def initialize(option)
        super("There is no config available for #{option} in any source.")
      end
    end
  end
end
