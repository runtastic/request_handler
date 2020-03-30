# frozen_string_literal: true

require 'request_handler/builder/base'

module RequestHandler
  module Builder
    class HeadersBuilder < Base
      Headers = Struct.new(:schema, :options)

      def create_klass_struct
        @result = Headers.new
      end

      def schema(value)
        @result.schema = value
      end

      def options(value)
        @result.options = value
      end
    end
  end
end
