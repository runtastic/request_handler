# frozen_string_literal: true

require 'request_handler/error'
require 'request_handler/schema_parser'
require 'request_handler/error'
require 'request_handler/json_api_data_parser'
module RequestHandler
  class MultipartsParser
    def initialize(request:, multipart_config:)
      @request = request
      @params = request.params
      @multipart_config = multipart_config
      missing_arguments = []
      missing_arguments << { params: 'is missing' } if params.nil?
      missing_arguments << { multipart_config: 'is missing' } if multipart_config.nil?
      raise MissingArgumentError, missing_arguments unless missing_arguments.empty?
    end

    def run
      multipart_config.keys.reduce({}) do |memo, name|
        raise ExternalArgumentError, multipart: 'missing' if params[name.to_s].nil?
        memo[name] = parse_part(name)
        memo
      end
    end

    private

    def parse_part(name)
      if lookup("#{name}.schema")
        JsonApiDataParser.new(
          data:             MultiJson.load(params[name.to_s]),
          schema:           lookup("#{name}.schema"),
          schema_options:   execute_options(lookup("#{name}.options")),
          included_schemas: lookup("#{name}.included")
        ).run
      else
        params[name.to_s]
      end
    end

    def lookup(key)
      multipart_config.lookup!(key)
    end

    def execute_options(options)
      return {} if options.nil?
      return options unless options.respond_to?(:call)
      options.call(self, request)
    end

    attr_reader :params, :request, :multipart_config
  end
end
