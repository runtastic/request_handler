# frozen_string_literal: true

require 'request_handler/version'
require 'request_handler/base'
require 'request_handler/validation/dry_engine'
require 'confstruct'
require 'dry-validation'
require 'multi_json'
require 'logger'

module RequestHandler
  class << self
    def configure(&block)
      configuration.configure(&block)
    end

    def configuration
      @configuration ||= ::Confstruct::Configuration.new do
        logger Logger.new(STDOUT)
        separator '__'
        validation_engine Validation::DryEngine
        raise_jsonapi_errors false
      end
    end

    def separator
      configuration.separator
    end

    def engine
      configuration.validation_engine
    end
  end
end
