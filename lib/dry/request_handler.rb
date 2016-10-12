# frozen_string_literal: true
require "dry/request_handler/version"
require "dry/request_handler/base"
require "confstruct"
require "dry-validation"
require "multi_json"
module Dry
  module RequestHandler
    class << self
      def configure(&block)
        @configuration ||= ::Confstruct::Configuration.new
        @configuration.configure(&block)
      end
      attr_accessor :configuration
    end
    require ::File.expand_path("../../../config/environments/#{ENV['ENVIRONMENT']}",  __FILE__)
  end
end
