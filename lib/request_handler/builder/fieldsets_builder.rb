# frozen_string_literal: true

require "request_handler/builder/base"
require "request_handler/builder/fieldsets_resource_builder"

Fieldset = Struct.new(:allowed, :required)

module RequestHandler
  module Builder
    class FieldsetsBuilder < Base
      def create_klass_struct
        @result = Fieldset.new
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
