# frozen_string_literal: true

require 'request_handler/builder/base'

IncludeOptions = Struct.new(:allowed, :default)

module RequestHandler
  module Builder
    class IncludeOptionsBuilder < Base
      def create_klass_struct
        @result = IncludeOptions.new
      end

      def allowed(value)
        @result.allowed = value
      end

      def default(value)
        @result.default = value
      end
    end
  end
end
