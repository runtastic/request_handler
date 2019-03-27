
module RequestHandler
  module Validation
    class Result
      attr_accessor :errors, :output

      def initialize(errors:, output:)
        self.errors = errors
        self.output = output
      end

      def valid?
        errors.empty?
      end
    end
  end
end
