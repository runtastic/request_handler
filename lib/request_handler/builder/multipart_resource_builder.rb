# frozen_string_literal: true

require 'request_handler/builder/base'

MultipartResource = Struct.new(:required, :schema, :type, :options)

module RequestHandler
  module Builder
    class MultipartResourceBuilder < Base
      def create_klass_struct
        @result = MultipartResource.new
      end

      def type(value)
        @result.type = value
      end

      def required(value)
        @result.required = value
      end

      def resource(name, &block)
        @result[name.to_sym] = build_multipart_resource(&block)
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
