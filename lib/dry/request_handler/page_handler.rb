# frozen_string_literal: true
module Dry
  module RequestHandler
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
  end
end
