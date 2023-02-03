# frozen_string_literal: true

require "request_handler/builder/base"

module RequestHandler
  module Builder
    class IncludeOptionsBuilder < Base
      IncludeOptions = Struct.new(:allowed, :defaults)

      def create_klass_struct
        @result = IncludeOptions.new
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
