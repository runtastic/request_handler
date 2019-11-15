# frozen_string_literal: true

require 'request_handler/builder/base'

module RequestHandler
  module Builder
    class FilterBuilder < Base
      Filter = Struct.new(:schema, :additional_url_filter, :options, :defaults)

      def create_klass_struct
        @result = Filter.new
      end

      def schema(value)
        @result.schema = value
      end

      def additional_url_filter(value)
        @result.additional_url_filter = value
      end

      def options(value)
        @result.options = value
      end

      def defaults(value)
        @result.defaults = value
      end
    end
  end
end
