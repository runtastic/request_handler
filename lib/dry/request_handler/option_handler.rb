# frozen_string_literal: true
module Dry
  module RequestHandler
    class OptionHandler
      def initialize(params:, allowed_options_type:)
        raise ArgumentError if params.nil?
        @params = params
        @allowed_options_type = allowed_options_type
      end

      private

      attr_reader :params, :allowed_options_type
    end
  end
end
