# frozen_string_literal: true
require "dry/request_handler/version"
require "confstruct"
require "dry-validation"
require "multi_json"

module Dry
  module RequestHandler
    # TODO: gem_config for global gem config missing, i.e. logger instance of can be passed into gem

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
        # TODO: move string into constant
        headers.fetch("ACCEPT", nil)
      end

      def auth
        # TODO: move string into constant
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
        raise "schema error" if validator.failure? # TODO: proper error
        validator.output
      end

      private

      attr_reader :filter, :schema, :schema_options
    end

    class BodyHandler # TODO: shared base with FilterHandler?
      def initialize(request:, schema:, schema_options: {})
        @request = request
        @schema = schema
        @schema_options = schema_options
      end

      def run
        validator = schema.with(schema_options).call(flattened_request_body)
        raise "schema error" if validator.failure? # TODO: proper error
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
          apply_max_size_constraint(size.to_i, prefix)
        end
      end

      def apply_max_size_constraint(size, prefix)
        max_size = lookup_nested_config_key("max_size", prefix)
        if max_size
          [max_size, size].min
        else
          # TODO: print a warning to make the user add a max_size config
          # use logger singleton to make use of log levels
          size
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
        # TODO: see concerns in config getter method
        @config = Confstruct::Configuration.new(&block)
      end

      def initialize(request:)
        @request = request
      end

      # TODO: memorize
      def filter_params
        FilterHandler.new(
          params:                params,
          schema:                config.lookup!("filter.schema"),
          additional_url_filter: config.lookup!("filter.additional_url_filter"),
          schema_options:        execute_options(config.lookup!("filter.options"))
        ).run
      end

      # TODO: memorize
      def page_params
        PageHandler.new(
          params:      params,
          page_config: config.lookup!("page")
        ).run
      end

      # TODO: memorize
      def include_params
        IncludeOptionHandler.new(
          params:               params,
          allowed_options_type: config.lookup!("include_options.allowed")
        ).run
      end

      # TODO: memorize
      def sort_params
        SortOptionHandler.new(
          params:               params,
          allowed_options_type: config.lookup!("sort_options.allowed")
        ).run
      end

      # TODO: memorize
      def authorization_headers
        AuthorizationHandler.new(env: request.env).run
      end

      # TODO: memorize
      def body_params
        BodyHandler.new(
          request:        request,
          schema:         config.lookup!("body.schema"),
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
        # TODO: not sure about this yet.
        # request isn't enough if I want to access body options for filter schema validation w/o reparsing the raw body
        # handler isn't enough if I want or need to access the raw request (to avoid a dependency loop)
        # Right now also the user has to take care of not creating a dependency loop between the parts
        options.call(self, request)
      end

      def params
        @params ||= _deep_transform_keys_in_object(request.params) { |k| k.tr(".", "_") }
      end

      # TODO: make sure this doesn't blow up with inheritence of request_handler classes
      # maybe overwriting the `inherited` method to dup the parents config?
      def config
        self.class.instance_variable_get("@config")
      end

      # extracted out of active_support
      # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/hash/keys.rb#L143
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
