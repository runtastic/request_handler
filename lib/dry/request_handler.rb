# frozen_string_literal: true
require "dry/request_handler/version"
require "confstruct"
require "dry-validation"
require "multi_json"

module Dry
  module RequestHandler
    class OptionHandler
      def initialize(params:, allowed_options_type:)
        @params = params
        @allowed_options_type = allowed_options_type
      end

      private

      attr_reader :params, :allowed_options_type
    end
    class SortOptionHandler < OptionHandler
      def run
        params.fetch("sort") { "" }.split(",").map do |option|
          name, order = if option.start_with?("-")
                          [option[1..-1], :desc]
                        else
                          [option, :asc]
                        end
          allowed_options_type.call(name) if allowed_options_type
          { name.to_sym => order }
        end
      end
    end

    class IncludeOptionHandler < OptionHandler
      def run
        params.fetch("include") { "" }.split(",").map do |option|
          allowed_options_type.call(option) if allowed_options_type
          option.to_sym
        end
      end
    end

    class AuthorizationHandler
      def initialize(env:)
        @headers = env.select { |k, _v| k.start_with?("HTTP_") }
      end

      def run
        {
          accept: accept,
          auth: auth
        }
      end

      private

      attr_reader :headers

      def accept
        headers.fetch("ACCEPT", nil)
      end

      def auth
        headers.fetch("HTTP_AUTH", nil)
      end
    end

    class FilterHandler
      def initialize(params:, schema:, additional_url_filter:, schema_options: {})
        @filter = params.fetch("filter") { {} }
        @schema = schema
        @schema_options = schema_options
        Array(additional_url_filter).each do |key|
          key = key.to_s
          @filter[key] = params.fetch(key)
        end
      end

      def run
        validator = schema.with(schema_options).call(filter)
        raise "schema error" if validator.failure?
        validator.output
      end

      private

      attr_reader :filter, :schema, :schema_options
    end

    class BodyHandler
      def initialize(request:, schema:, schema_options: {})
        @request = request
        @schema = schema
        @schema_options = schema_options
      end

      def run
        validator = schema.with(schema_options).call(flattened_request_body)
        raise "schema error" if validator.failure?
        validator.output
      end

      private

      def flattened_request_body
        body = request_body["data"]
        body.merge!(body.delete("attributes") { {} })
        relationships = flatten_relationship_resource_linkages(body.delete("relationships") { {} })
        body.merge!(relationships)
        body
      end

      def flatten_relationship_resource_linkages(relationships)
        relationships.each_with_object({}) do |(k, v), memo|
          resource_linkage = v["data"]
          next if resource_linkage.nil?
          memo[k] = resource_linkage
        end
      end

      def request_body # TODO: check if this is the best way to get the body
        b = request.body
        b.rewind
        b = b.read
        b.empty? ? {} : MultiJson.load(b)
      end

      attr_reader :request, :schema, :schema_options
    end

    class PageHandler
      def initialize(params:, page_config:)
        @page_options = params.fetch("page") { {} }
        @config = page_config
      end

      def run
        base = { number: extract_number, size: extract_size }

        config.keys.reduce(base) do |memo, key|
          next memo if TOP_LEVEL_PAGE_KEYS.include?(key)
          memo.merge!("#{key}_number".to_sym => extract_number(prefix: key),
                      "#{key}_size".to_sym   => extract_size(prefix: key))
        end
      end

      private

      TOP_LEVEL_PAGE_KEYS = Set.new([:default_size, :max_size])
      attr_reader :page_options, :config

      def extract_number(prefix: nil)
        Integer(lookup_nested_params_key("number", prefix) || 1)
      end

      def extract_size(prefix: nil)
        size = lookup_nested_params_key("size", prefix).to_i
        if size.zero?
          lookup_nested_config_key("default_size", prefix)
        else
          max_size = lookup_nested_config_key("max_size", prefix)
          if max_size
            [max_size, size.to_i].min
          else
            # warning
            size.to_i
          end
        end
      end

      def lookup_nested_config_key(key, prefix)
        key = prefix ? "#{prefix}.#{key}" : key
        config.lookup!(key) # || warning
      end

      def lookup_nested_params_key(key, prefix)
        key = prefix ? "#{prefix}_#{key}" : key
        page_options.fetch(key, nil)
      end
    end

    class Base
      def self.options(&block)
        @config = Confstruct::Configuration.new(&block)
      end

      def initialize(request:)
        @request = request
      end

      def filter_params
        FilterHandler.new(
          params:                params,
          schema:                config.lookup!("filter.schema"),
          additional_url_filter: config.lookup!("filter.additional_url_filter"),
          schema_options: execute_options(config.lookup!("filter.options"))
        ).run
      end

      def page_params
        PageHandler.new(
          params:      params,
          page_config: config.lookup!("page")
        ).run
      end

      def include_params
        IncludeOptionHandler.new(
          params:               params,
          allowed_options_type: config.lookup!("include_options.allowed")
        ).run
      end

      def sort_params
        SortOptionHandler.new(
          params:               params,
          allowed_options_type: config.lookup!("sort_options.allowed")
        ).run
      end

      def authorization_headers
        AuthorizationHandler.new(env: request.env).run
      end

      def body_params
        BodyHandler.new(
          request: request,
          schema: config.lookup!("body.schema"),
          schema_options: execute_options(config.lookup!("body.options"))
        ).run
      end

      # @abstract Subclass is expected to implement #to_dto
      # !method to_dto
      #   take the parsed values and return as application specific data transfer object

      private

      attr_reader :request

      def execute_options(options)
        return {} if options.nil?
        return options unless options.respond_to?(:call)
        options.call(self, request)
      end

      def params
        @params ||= _deep_transform_keys_in_object(request.params) { |k| k.tr(".", "_") }
      end

      def config
        self.class.instance_variable_get("@config")
      end

      def _deep_transform_keys_in_object(object, &block)
        case object
        when Hash
          object.each_with_object({}) do |(key, value), result|
            result[yield(key)] = _deep_transform_keys_in_object(value, &block)
          end
        when Array
          object.map { |e| _deep_transform_keys_in_object(e, &block) }
        else
          object
        end
      end
    end
  end
end
