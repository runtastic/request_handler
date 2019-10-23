# frozen_string_literal: true

require 'request_handler/filter_parser'
require 'request_handler/page_parser'
require 'request_handler/include_option_parser'
require 'request_handler/sort_option_parser'
require 'request_handler/header_parser'
require 'request_handler/body_parser'
require 'request_handler/multipart_parser'
require 'request_handler/fieldsets_parser'
require 'request_handler/query_parser'
require 'request_handler/helper'
require 'confstruct'
module RequestHandler
  class Base
    class << self
      def options(hash)
        @config ||= hash
      end

      def inherited(subclass)
        return if @config.nil?
        subclass.config = @config.deep_copy
      end

      attr_accessor :config
    end
    def initialize(request:)
      raise MissingArgumentError, request: 'is missing' if request.nil?
      @request = request
    end

    def filter_params
      @filter_params ||= parse_filter_params
    end

    def page_params
      @page_params ||= PageParser.new(
        params:      params,
        page_config: lookup!('page')
      ).run
    end

    def include_params
      @include_params ||= parse_include_params
    end

    def sort_params
      @sort_params ||= parse_sort_params
    end

    def headers
      @headers ||= HeaderParser.new(env: request.env).run
    end

    def body_params
      @body_params ||= parse_body_params
    end

    def multipart_params
      @multipart_params ||= parse_multipart_params
    end

    def fieldsets_params
      @fieldsets_params ||= parse_fieldsets_params
    end

    def query_params
      @query_params ||= parse_query_params
    end

    # @abstract Subclass is expected to implement #to_dto
    # !method to_dto
    #   take the parsed values and return as application specific data transfer object

    private

    attr_reader :request

    def parse_filter_params
      defaults = fetch_defaults('filter.defaults', {})
      defaults.merge(FilterParser.new(
        params:                params,
        schema:                lookup!('filter.schema'),
        additional_url_filter: lookup('filter.additional_url_filter'),
        schema_options:        execute_options(lookup('filter.options'))
      ).run)
    end

    def parse_include_params
      parse_options(type: 'include_options', parser: IncludeOptionParser)
    end

    def parse_sort_params
      parse_options(type: 'sort_options', parser: SortOptionParser)
    end

    def parse_options(type:, parser:)
      defaults = fetch_defaults("#{type}.defaults", [])
      result = parser.new(
        params:               params,
        allowed_options_type: lookup!("#{type}.allowed")
      ).run
      result.empty? ? defaults : result
    end

    def parse_body_params
      BodyParser.new(
        request:          request,
        schema:           lookup!('body.schema'),
        schema_options:   execute_options(lookup('body.options')),
        type:             lookup('body.type')
      ).run
    end

    def parse_multipart_params
      MultipartsParser.new(
        request:           request,
        multipart_config: lookup!('multipart')
      ).run
    end

    def parse_fieldsets_params
      FieldsetsParser.new(params:   params,
                          allowed:  lookup!('fieldsets.allowed'),
                          required: lookup('fieldsets.required') || []).run
    end

    def parse_query_params
      QueryParser.new(
        params:         params,
        schema:         lookup!('query.schema'),
        schema_options: execute_options(lookup('query.options'))
      ).run
    end

    def fetch_defaults(key, default)
      value = lookup(key)
      return default if value.nil?
      return value unless value.respond_to?(:call)
      value.call(request)
    end

    def execute_options(options)
      return {} if options.nil?
      return options unless options.respond_to?(:call)
      options.call(self, request)
    end

    def lookup!(key)
      config.dig(*symbolize_key(key)) do |data|
        raise NoConfigAvailableError, key.to_sym => 'is not configured' if data.nil?
      end
    end

    def lookup(key)
      config.dig(*symbolize_key(key))
    end

    def symbolize_key(key)
      key.split('.').map(&:to_sym)
    end

    def params
      raise MissingArgumentError, params: 'is missing' if request.params.nil?
      raise ExternalArgumentError, [] unless request.params.is_a?(Hash)
      @params ||= Helper.deep_transform_keys_in_object(request.params) do |k|
        k.to_s.gsub('.', separator)
      end
    end

    def config
      self.class.instance_variable_get('@config')
    end

    def separator
      ::RequestHandler.configuration.separator
    end
  end
end
