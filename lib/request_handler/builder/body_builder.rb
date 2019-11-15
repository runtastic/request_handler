# frozen_string_literal: true

require 'request_handler/builder/base'

module RequestHandler
  module Builder
    class BodyBuilder < Base
      Body = Struct.new(:type, :schema, :options)

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
