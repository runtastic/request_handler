# frozen_string_literal: true

require "request_handler/builder/base"

Query = Struct.new(:schema, :options)

module RequestHandler
  module Builder
    class QueryBuilder < Base
      def create_klass_struct
        @result = Query.new
      end

      def schema(&block)
        @result.schema = Class.new(Dry::Validation::Contract) do
          instance_eval(&block)
        end
      end

      def options(value)
        @result.options = value
      end
    end
  end
end
