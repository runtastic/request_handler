# frozen_string_literal: true
module Dry
  module RequestHandler
    class OptionHandler
      def initialize(params:, allowed_options_type:)
        if params.nil? || !params.class.equal?(Hash) || !allowed_options_type.class.equal?(Dry::Types::Enum)
          raise ArgumentError
        end
        @params = params
        @allowed_options_type = allowed_options_type
      end

      private

      attr_reader :params, :allowed_options_type
    end
  end
end
