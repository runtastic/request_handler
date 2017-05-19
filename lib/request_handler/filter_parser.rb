# frozen_string_literal: true

require 'request_handler/schema_parser'
require 'request_handler/error'
module RequestHandler
  class FilterParser < SchemaParser
    def initialize(params:, schema:, additional_url_filter:, schema_options: {})
      super(schema: schema, schema_options: schema_options)
      @filter = params.fetch('filter') { {} }
      raise FilterParamsError, filter: 'must be a Hash' unless @filter.is_a?(Hash)
      Array(additional_url_filter).each do |key|
        key = key.to_s
        raise build_error(key) unless @filter[key].nil?
        @filter[key] = params.fetch(key) { nil }
      end
    end

    def run
      validate_schema(filter)
    end

    private

    def build_error(_key)
      InternalArgumentError.new(filter: 'the filter key was set twice')
    end

    attr_reader :filter
  end
end
