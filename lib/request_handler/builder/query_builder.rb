# frozen_string_literal: true

require 'request_handler/builder/base'

module RequestHandler
  module Builder
    class QueryBuilder < Base
      Query = Struct.new(:schema, :options)

      def create_klass_struct
        @result = Query.new
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
