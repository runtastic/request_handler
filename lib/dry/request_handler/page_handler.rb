# frozen_string_literal: true
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class PageHandler
      def initialize(params:, page_config:)
        missing_arguments = []
        missing_arguments << { params: "is missing" } if params.nil?
        missing_arguments << { page_config: "is missing" } if page_config.nil?
        raise MissingArgumentError.new(missing_arguments) unless missing_arguments.empty?
        @page_options = params.fetch("page") { {} }
        raise ExternalArgumentError.new(page: "must be a Hash") unless @page_options.is_a?(Hash)
        @config = page_config
      end

      def run
        base = { number: extract_number, size: extract_size }
        cfg = config.keys.reduce(base) do |memo, key|
          next memo if TOP_LEVEL_PAGE_KEYS.include?(key)
          memo.merge!("#{key}_number".to_sym => extract_number(prefix: key),
                      "#{key}_size".to_sym   => extract_size(prefix: key))
        end
        check_for_missing_options(cfg)
        cfg
      end

      private

      TOP_LEVEL_PAGE_KEYS = Set.new([:default_size, :max_size])
      attr_reader :page_options, :config

      def check_for_missing_options(config)
        missing_arguments = page_options.keys - config.keys.map(&:to_s)
        warn "client sent unknown option " + missing_arguments.to_s  unless missing_arguments.empty?
      end

      def extract_number(prefix: nil)
        number_string = lookup_nested_params_key("number", prefix) || 1
        error_msg = { :"#{prefix}_number"=> "must be a positive Integer" }
        check_int(string: number_string, error_msg: error_msg)
      end

      def extract_size(prefix: nil)
        size = fetch_and_check_size(prefix)
        default_size = fetch_and_check_default_size(prefix)
        return default_size if size.nil?
        apply_max_size_constraint(size, prefix)
      end

      def fetch_and_check_default_size(prefix)
        default_size = lookup_nested_config_key("default_size", prefix)
        raise NoConfigAvailableError.new("#{prefix}_size".to_sym => "has no default_size") if default_size.nil?
        error_msg = { :"#{prefix}_size" => "must be a positive Integer" }
        raise InternalArgumentError.new(error_msg) unless default_size.is_a?(Integer) && default_size.positive?
        default_size
      end

      def fetch_and_check_size(prefix)
        size_string = lookup_nested_params_key("size", prefix)
        return nil if size_string.nil?
        error_msg = { :"#{prefix}_size" => "must be a positive Integer" }
        check_int(string: size_string, error_msg: error_msg) unless size_string.nil?
      end

      def check_int(string:, error_msg:)
        output = Integer(string)
        raise ExternalArgumentError.new(error_msg) unless output.positive?
        output
      rescue ArgumentError
        raise ExternalArgumentError.new(error_msg)
      end

      def apply_max_size_constraint(size, prefix)
        max_size = lookup_nested_config_key("max_size", prefix)
        case max_size
        when Integer
          [max_size, size].min
        when nil
          warn "#{prefix} max_size config not set"
          size
        else
          raise InternalArgumentError.new("#{prefix} max_size".to_sym => "must be a positive Integer")
        end
      end

      def lookup_nested_config_key(key, prefix)
        key = prefix ? "#{prefix}.#{key}" : key
        config.lookup!(key)
      end

      def lookup_nested_params_key(key, prefix)
        key = prefix ? "#{prefix}_#{key}" : key
        page_options.fetch(key, nil)
      end

      def warn(message)
        ::Dry::RequestHandler.configuration.logger.warn(message)
      end
    end
  end
end
