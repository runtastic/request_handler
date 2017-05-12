# frozen_string_literal: true
require 'request_handler/error'
require 'request_handler/schema_parser'
require 'request_handler/error'
require 'request_handler/json_api_parser'
module RequestHandler
  class MultipartsParser
    def initialize(request:, multiparts_config:)
      missing_arguments = []
      missing_arguments << { params: 'is missing' } if request.params.nil?
      missing_arguments << { multiparts_config: 'is missing' } if multiparts_config.nil?
      raise MissingArgumentError, missing_arguments unless missing_arguments.empty?
      multiparts_config.keys.each do |name|
        raise ExternalArgumentError, multiparts: 'missing' if params[name.to_s].nil?
      end
      @request = request
      @multiparts_config = multiparts_config
    end

    def run; end

    private

    def multiparts; end

    attr_reader :request, :multiparts_config
  end
end
