# frozen_string_literal: true
require 'request_handler/version'
require 'request_handler/base'
require 'confstruct'
require 'dry-validation'
require 'multi_json'
require 'logger'

module RequestHandler
  class << self
    def configure(&block)
      @configuration.configure(&block)
    end

    def configuration
      @configuration ||= ::Confstruct::Configuration.new do
        logger Logger.new(STDOUT)
        separator '__'
      end
    end

    def separator
      configuration.separator
    end
  end
end
