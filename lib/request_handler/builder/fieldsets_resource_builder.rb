# frozen_string_literal: true

require "request_handler/builder/base"
require "ostruct"

module RequestHandler
  module Builder
    class FieldsetsResourceBuilder < Base
      def create_klass_struct
        @result = OpenStruct.new
      end

      def resource(name, value)
        @result[name.to_sym] = value
      end
    end
  end
end
