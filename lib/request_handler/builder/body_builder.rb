# frozen_string_literal: true

require 'request_handler/builder/base'

Body = Struct.new(:type, :schema, :options)

module RequestHandler
  module Builder
    class BodyBuilder < Base
      def create_klass_struct
        @result = Body.new
      end

      def type(value)
        @result.type = value
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
