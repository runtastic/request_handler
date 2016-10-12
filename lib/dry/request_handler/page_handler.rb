# frozen_string_literal: true
module Dry
  module RequestHandler
    class PageHandler
      def initialize(params:, page_config:)
        raise ArgumentError if params.nil? || page_config.nil?
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
        number = Integer(lookup_nested_params_key("number", prefix) || 1)
        raise ArgumentError unless number.positive?
        number
      rescue ArgumentError # For future error change
        raise ArgumentError
      end

      def extract_size(prefix: nil)
        size = fetch_and_check_size(prefix)
        return lookup_nested_config_key("default_size", prefix) if size.nil? || size.zero?
        apply_max_size_constraint(size, prefix)
      end

      def fetch_and_check_size(prefix)
        size_string = lookup_nested_params_key("size", prefix)
        unless size_string.nil?
          begin
            size = Integer(size_string)
            raise ArgumentError if size.negative?
            size
          rescue TypeError
            raise ArgumentError
          end
        end
      end

      def apply_max_size_constraint(size, prefix)
        max_size = lookup_nested_config_key("max_size", prefix)
        if max_size
          [max_size, size].min
        else
          # TODO: print a warning to make the user add a max_size config
          # use logger singleton to make use of log levels
          ::Dry::RequestHandler.configuration.logger.warn "max size config not set"
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
  end
end
