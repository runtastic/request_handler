# frozen_string_literal: true

require 'pry'
module RequestHandler
  module Builder
    class Base
      attr_accessor :result

      def initialize
        create_klass_struct
        # create_block_methods(blocks)
        # create_variables_methods(variables)
      end

      # def create_variables_methods(variables)
      #   variables.each do |variable_method|
      #     Kernel.define_method variable_method do |value|
      #       result = instance_variable_get(:@result)
      #       result ||= create_klass_struct
      #       result[variable_method] = value
      #       instance_variable_set(:@result, result)
      #       # result.send(variable_method, value)
      #     end
      #   end
      # end
      #
      # def create_block_methods(blocks)
      #   blocks.each do |block_method|
      #     Kernel.define_method block_method do |&block|
      #       res = instance_variable_get(:@result)
      #       res ||= create_klass_struct
      #       binding.pry
      #       res[block_method] = send("build_#{block_method.to_s}".to_sym, &block)
      #       instance_variable_set(:@result, res)
      #       # @result.send(block_method, send("build_#{block_method.to_s}".to_sym, &block))
      #     end
      #   end
      # end

      def create_klass_struct
        raise NotImplementedError
      end

      def build
        result
      end
    end
  end
end
