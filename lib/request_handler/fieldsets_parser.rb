# frozen_string_literal: true

require "request_handler/schema_parser"
require "request_handler/error"
module RequestHandler
  class FieldsetsParser
    def initialize(params:, allowed: {}, required: [])
      @params = params
      allowed.reject! { |_k, v| v == false }
      allowed.each_pair do |_key, value|
        raise InternalArgumentError.new(allowed: "must be a Schema or a Boolean") unless
          RequestHandler.configuration.validation_engine.valid_schema?(value) ||
            value.is_a?(TrueClass) || value.is_a?(FalseClass)
      end
      @allowed = allowed
      raise InternalArgumentError.new(required: "must be an Array") unless required.is_a?(Array)

      @required = required
    end

    def run
      fields = params["fields"]
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
      values.split(",").map! do |option|
        parse_option(type, option)
      end
    end

    def parse_option(type, option)
      if allowed[type] == true
        option.to_sym
      else
        RequestHandler.configuration.validation_engine.validate!(option, allowed[type]).output.to_sym
      end
    rescue Validation::Error
      raise FieldsetsParamsError.new([{ code:   "INVALID_QUERY_PARAMETER",
                                        status: "400",
                                        detail: "allowed fieldset does not include '#{option}'",
                                        source: { parameter: "fields[#{type}]" } }])
    end

    def check_required_fieldsets_types(fieldsets)
      missing = required - fieldsets.keys
      return fieldsets if missing.empty?

      raise_missing_fieldsets!(missing)
    end

    def raise_invalid_field_option(type)
      return if allowed[type]

      raise OptionNotAllowedError.new([
                                        {
                                          code:   "INVALID_QUERY_PARAMETER",
                                          status: "400",
                                          detail: "fieldset for '#{type}' not allowed",
                                          source: { parameter: "fields[#{type}]" }
                                        }
                                      ])
    end

    def raise_missing_fields_param
      return if required.empty?

      raise_missing_fieldsets!(required)
    end

    def raise_missing_fieldsets!(missing)
      errors = missing.map do |type|
        {
          code:   "MISSING_QUERY_PARAMETER",
          status: "400",
          source: { parameter: "" },
          detail: "missing required parameter fields[#{type}]"
        }
      end
      raise FieldsetsParamsError.new(errors)
    end

    attr_reader :params, :allowed, :required
  end
end
