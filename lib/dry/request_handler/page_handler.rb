# frozen_string_literal: true
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class PageHandler
      def initialize(params:, page_config:)
        missing_arguments = []
        missing_arguments << { params: "is missing" } if params.nil?
        missing_arguments << { page_config: "is missing" } if page_config.nil?
        raise MissingArgumentError.new(missing_arguments) if missing_arguments.length.positive?
        @page_options = params.fetch("page") { {} }
        raise WrongArgumentTypeError.new(page: "must be a Hash") unless @page_options.is_a?(Hash)
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
        number = Integer(lookup_nested_params_key("number", prefix) || 1)
        raise InvalidArgumentError.new("#{prefix}_number".to_sym => "must be a positive Integer") unless number.positive?
        number
      rescue ArgumentError
        raise WrongArgumentTypeError.new("#{prefix}_number".to_sym => "must be a positive Integer")
      end

      def extract_size(prefix: nil)
        size = fetch_and_check_size(prefix)
        default_size = fetch_and_check_default_size(prefix)
        if size.nil? || size.zero?
          raise NoConfigAvailableError.new("#{prefix}_size".to_sym => "is defined nowhere") if default_size.nil? || default_size.zero?
          return default_size
        end
        warn "#{prefix} default_size config not set" if default_size.nil?
        apply_max_size_constraint(size, prefix)
      end

      def fetch_and_check_default_size(prefix)
        default_size_string = lookup_nested_config_key("default_size", prefix)
        check_size(size_string: default_size_string, size_key: "default_size")
      end

      def fetch_and_check_size(prefix)
        size_string = lookup_nested_params_key("size", prefix)
        check_size(size_string: size_string, size_key: "#{prefix}_size")
      end

      def check_size(size_string:, size_key:)
        unless size_string.nil?
          begin
            size = Integer(size_string)
            raise InvalidArgumentError.new(size_key.to_sym => "must be a positive Integer") unless size.positive?
            size
          rescue ArgumentError
            raise WrongArgumentTypeError.new(size_key.to_sym => "must be a positive Integer")
          end
        end
      end

      def apply_max_size_constraint(size, prefix)
        max_size = lookup_nested_config_key("max_size", prefix)
        if max_size
          [max_size, size].min
        else
          warn "#{prefix} max_size config not set"
          size
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
