# frozen_string_literal: true

require 'pry'
module RequestHandler
  module Builder
    class Base
      attr_accessor :result

      def initialize
        create_klass_struct
      end

      def create_klass_struct
        raise NotImplementedError
      end

      def build
        result
      end
    end
  end
end
