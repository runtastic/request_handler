# frozen_string_literal: true

require "request_handler/builder/base"

module RequestHandler
  module Builder
    class PageResourceBuilder < Base
      PageResource = Struct.new(:default_size, :max_size)

      def create_klass_struct
        @result = PageResource.new
      end

      def default_size(value)
        @result.default_size = value
      end

      def max_size(value)
        @result.max_size = value
      end
    end
  end
end
