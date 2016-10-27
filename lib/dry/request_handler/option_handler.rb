# frozen_string_literal: true
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class OptionHandler
      def initialize(params:, allowed_options_type:)
        @params = params
        @allowed_options_type = allowed_options_type
        raise WrongArgumentTypeError.new(allowed_options_type: "must be a Enum") unless enum?
      end

      private

      def enum?
        @allowed_options_type.class.equal?(Dry::Types::Enum)
      end

      def empty_param?(param)
        params.fetch(param) { nil } == ""
      end
      attr_reader :params, :allowed_options_type
    end
  end
end
