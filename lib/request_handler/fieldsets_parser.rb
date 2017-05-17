# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
module RequestHandler
  class FieldsetsParser
    def initialize(params:, allowed: {}, required: [])
      @params = params
      allowed.reject! { |_k, v| v == false }
      allowed.each_value do |option|
        raise InternalArgumentError, allowed: 'must be a Enum or a Boolean' unless
              option.is_a?(Dry::Types::Enum) || option.is_a?(TrueClass)
      end
      @allowed = allowed
      raise InternalArgumentError, required: 'must be an Array' unless required.is_a?(Array)
      @required = required
    end

    def run
      fields = params['fields']
      raise_missing_fields_param unless fields
      fieldsets = fields.to_h.each_with_object({}) do |(type, values), memo|
        type = type.to_sym
        raise_invalid_field_option(type)
        memo[type] = parse_options(type, values)
      end
      check_required_fieldsets_types(fieldsets)
    end

    private

    def parse_options(type, values)
      values.split(',').map! do |option|
        parse_option(type, option)
      end
    end

    def parse_option(type, option)
      if allowed[type] == true
        option.to_sym
      else
        allowed[type].call(option).to_sym
      end
    rescue Dry::Types::ConstraintError
      raise FieldsetsParamsError, fieldsets: "invalid field: <#{option}> for type: #{type}"
    end

    def check_required_fieldsets_types(fieldsets)
      return fieldsets if (required - fieldsets.keys).empty?
      raise FieldsetsParamsError, fieldsets: 'missing required fieldsets parameter'
    end

    def raise_invalid_field_option(type)
      return if allowed.key?(type)
      raise OptionNotAllowedError, fieldsets: "fieldsets for type: #{type} not allowed"
    end

    def raise_missing_fields_param
      return if required.empty?
      raise FieldsetsParamsError, fieldsets: 'missing required fields options'
    end

    attr_reader :params, :allowed, :required
  end
end
