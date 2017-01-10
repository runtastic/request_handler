# frozen_string_literal: true
require 'request_handler/schema_handler'
require 'request_handler/error'
module RequestHandler
  class FieldSetHandler
    def initialize(params:, allowed: {}, required: [])
      @params = params
      allowed.each_value do |option|
        raise InternalArgumentError, allowed: 'must be a Enum' unless option.is_a?(Dry::Types::Enum)
      end
      @allowed = allowed
      raise InternalArgumentError, allowed: 'must be an Array' unless required.is_a?(Array)
      @required = required
    end

    def run
      fields = params['fields']
      raise_missing_fields_param unless fields

      field_set = fields.to_h.each_with_object({}) do |(type, values), memo|
        type = type.to_sym
        raise_invalid_field_option(type)
        memo[type] = parse_options(type, values)
      end
      check_required_field_set_types(field_set)
    end

    private

    def parse_options(type, values)
      values.split(',').map! do |option|
        parse_option(type, option)
      end
    end

    def parse_option(type, option)
      allowed[type].call(option).to_sym
    rescue Dry::Types::ConstraintError
      raise ExternalArgumentError, field_set: "invalid field: <#{option}> for type: #{type}"
    end

    def check_required_field_set_types(field_set)
      return field_set if (required - field_set.keys).empty?
      raise ExternalArgumentError, field_set: 'missing required field_set parameter'
    end

    def raise_invalid_field_option(type)
      return if allowed&.key?(type)
      raise OptionNotAllowedError, field_set: "field_set for type: #{type} not allowed"
    end

    def raise_missing_fields_param
      return if required.nil? || required.empty?
      raise ExternalArgumentError, field_set: 'missing required fields options'
    end

    attr_reader :params, :allowed, :required
  end
end
