# frozen_string_literal: true
require "dry/request_handler/filter_handler"
require "dry/request_handler/page_handler"
require "dry/request_handler/include_option_handler"
require "dry/request_handler/sort_option_handler"
require "dry/request_handler/autorization_handler"
require "dry/request_handler/body_handler"
require "confstruct"
module Dry
  module RequestHandler
    class Base
      class << self
        def options(&block)
          @config ||= ::Confstruct::Configuration.new
          @config.configure(&block)
        end

        def inherited(subclass)
          return if @config.nil?
          subclass.config = @config.deep_copy
        end

        attr_writer :config
      end
      def initialize(request:)
        @request = request
      end

      def filter_params
        @filter_params ||= FilterHandler.new(
          params:                params,
          schema:                config.lookup!("filter.schema"),
          additional_url_filter: config.lookup!("filter.additional_url_filter"),
          schema_options:        execute_options(config.lookup!("filter.options"))
        ).run
      end

      # TODO: memorize
      def page_params
        @page_handler ||= PageHandler.new(
          params:      params,
          page_config: config.lookup!("page")
        ).run
      end

      # TODO: memorize
      def include_params
        @include_params ||= IncludeOptionHandler.new(
          params:               params,
          allowed_options_type: config.lookup!("include_options.allowed")
        ).run
      end

      # TODO: memorize
      def sort_params
        @sort_params ||= SortOptionHandler.new(
          params:               params,
          allowed_options_type: config.lookup!("sort_options.allowed")
        ).run
      end

      # TODO: memorize
      def authorization_headers
        @authorization_headers ||= AuthorizationHandler.new(env: request.env).run
      end

      # TODO: memorize
      def body_params
        @body_params ||= BodyHandler.new(
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
