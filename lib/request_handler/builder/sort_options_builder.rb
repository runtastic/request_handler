# frozen_string_literal: true

require "request_handler/builder/base"

SortOptions = Struct.new(:allowed, :defaults)

module RequestHandler
  module Builder
    class SortOptionsBuilder < Base
      def create_klass_struct
        @result = SortOptions.new
      end

      def allowed(value)
        @result.allowed = value
      end

      def defaults(value)
        @result.defaults = value
      end
    end
  end
end
