# frozen_string_literal: true

require "request_handler/builder/base"

module RequestHandler
  module Builder
    class SortOptionsBuilder < Base
      SortOptions = Struct.new(:allowed, :defaults)

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
