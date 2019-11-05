# frozen_string_literal: true

require "request_handler/builder/base"

Resource = Struct.new(:default_size, :max_size)

module RequestHandler
  module Builder
    class ResourceBuilder < Base
      def create_klass_struct
        @result = Resource.new
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
