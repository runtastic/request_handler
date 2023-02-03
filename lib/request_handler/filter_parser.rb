# frozen_string_literal: true

require "request_handler/schema_parser"
require "request_handler/error"
module RequestHandler
  class FilterParser < SchemaParser
    def initialize(params:, schema:, additional_url_filter:, schema_options: {})
      super(schema: schema, schema_options: schema_options)
      @filter = params.fetch("filter") { {} }
      raise FilterParamsError.new([jsonapi_filter_syntax_error]) unless @filter.is_a?(Hash)

      Array(additional_url_filter).each do |key|
        key = key.to_s
        raise build_error(key) unless @filter[key].nil?

        @filter[key] = params.fetch(key, nil)
      end
    end

    def run
      validate_schema(filter)
    rescue SchemaValidationError => e
      raise FilterParamsError.new((e.errors.map do |schema_error|
        source_param = "filter[#{schema_error[:source][:pointer]}]"
        {
          detail: schema_error[:detail],
          **jsonapi_filter_base_error(source_param: source_param)
        }
      end))
    end

    private

    def build_error(_key)
      InternalArgumentError.new(filter: "the filter key was set twice")
    end

    def jsonapi_filter_base_error(source_param:)
      {
        status: "400",
        code:   "INVALID_QUERY_PARAMETER",
        source: { parameter: source_param }
      }
    end

    def jsonapi_filter_syntax_error
      {
        **jsonapi_filter_base_error(source_param: "filter"),
        links:  { about: "https://jsonapi.org/recommendations/#filtering" },
        detail: "Filter parameter must conform to JSON API recommendation"
      }
    end

    attr_reader :filter
  end
end
