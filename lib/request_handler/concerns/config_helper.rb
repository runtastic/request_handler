# frozen_string_literal: true

module RequestHandler
  module Concerns
    module ConfigHelper
      def lookup!(hash, key)
        hash.dig(*symbolize_key(key)).tap do |data|
          raise NoConfigAvailableError, key.to_sym => 'is not configured' if data.nil?
        end
      end

      def lookup(config, key)
        config.dig(*symbolize_key(key))
      end

      def symbolize_key(key)
        key.split('.').map(&:to_sym)
      end

      def deep_to_h(obj)
        obj.to_h.transform_values do |v|
          v.is_a?(OpenStruct) || v.is_a?(Struct) ? deep_to_h(v) : v
        end
      end
    end
  end
end
