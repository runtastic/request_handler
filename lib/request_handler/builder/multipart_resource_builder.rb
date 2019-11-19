# frozen_string_literal: true

require 'request_handler/builder/base'

module RequestHandler
  module Builder
    class MultipartResourceBuilder < Base
      MultipartResource = Struct.new(:required, :schema, :type, :options)

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
