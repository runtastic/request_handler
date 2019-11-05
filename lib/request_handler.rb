# frozen_string_literal: true

require 'request_handler/version'
require 'request_handler/base'
require 'request_handler/validation/dry_engine'
require 'dry-validation'
require 'multi_json'
require 'logger'
require 'gem_config'

module RequestHandler
  include GemConfig::Base

  with_configuration do
    has :validation_engine
    has :logger, default: Logger.new(STDOUT)
    has :separator, classes: [String], default: '__'
    has :raise_jsonapi_errors, default: false
  end
end
