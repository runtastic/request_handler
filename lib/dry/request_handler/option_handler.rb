# frozen_string_literal: true
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class OptionHandler
      def initialize(params:, allowed_options_type:)
        raise Dry::RequestHandler::MissingArgumentError.new(["params"]) if params.nil?
        raise Dry::RequestHandler::WrongArgumentTypeError.new("params") unless params.class.equal?(Hash)
        unless allowed_options_type.class.equal?(Dry::Types::Enum)
          raise Dry::RequestHandler::WrongArgumentTypeError.new("allowed_options_type")
        end
        @params = params
        @allowed_options_type = allowed_options_type
      end

      private

      attr_reader :params, :allowed_options_type
    end
  end
end
