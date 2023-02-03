# frozen_string_literal: true

require "request_handler/builder/base"
require "request_handler/builder/page_resource_builder"

module RequestHandler
  module Builder
    class PageBuilder < Base
      def create_klass_struct
        @result = OpenStruct.new
      end

      def default_size(value)
        @result.default_size = value
      end

      def max_size(value)
        @result.max_size = value
      end

      def resource(name, &block)
        @result[name.to_sym] = build_page_resource(&block)
      end

      def build_page_resource(&block)
        Docile.dsl_eval(PageResourceBuilder.new, &block).build
      end
    end
  end
end
