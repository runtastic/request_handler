# frozen_string_literal: true

require 'request_handler/builder/base'
require 'request_handler/builder/fieldsets_resource_builder'

module RequestHandler
  module Builder
    class FieldsetsBuilder < Base
      Fieldsets = Struct.new(:allowed, :required)

      def create_klass_struct
        @result = Fieldsets.new
      end

      def allowed(&block)
        @result.allowed = build_fieldsets_resource(&block)
      end

      def required(value)
        @result.required = value
      end

      def build_fieldsets_resource(&block)
        Docile.dsl_eval(FieldsetsResourceBuilder.new, &block).build
      end
    end
  end
end
