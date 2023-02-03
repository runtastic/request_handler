# frozen_string_literal: true

require "request_handler/builder/base"
require "request_handler/builder/multipart_resource_builder"

module RequestHandler
  module Builder
    class MultipartBuilder < Base
      def create_klass_struct
        @result = OpenStruct.new
      end

      def resource(name, &block)
        @result[name.to_sym] = build_multipart_resource(&block)
      end

      def build_multipart_resource(&block)
        Docile.dsl_eval(MultipartResourceBuilder.new, &block).build
      end
    end
  end
end
