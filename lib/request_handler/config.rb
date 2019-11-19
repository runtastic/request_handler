# frozen_string_literal: true

require 'docile'

module RequestHandler
  class Config
    def initialize(&block)
      @config = Docile.dsl_eval(RequestHandler::Builder::OptionsBuilder.new, &block).build
    end

    attr_accessor :config

    def lookup!(key)
      lookup(key) || (raise NoConfigAvailableError, key.to_sym => 'is not configured')
    end

    def lookup(key)
      @config.dig(*symbolize_key(key))
    end

    private

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
