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
      multipart_config.keys.each_with_object({}) do |name, memo|
        raise ExternalArgumentError, multipart: 'missing' if params[name.to_s].nil?
        memo[name] = parse_part(name)
      end
    end

    private

    def parse_part(name)
      raise ExternalArgumentError, multipart_file: 'missing' if multipart_file(name).nil?
      if lookup("#{name}.schema")
        parse_data(name)
      else
        params[name.to_s]
      end
    end

    def parse_data(name)
      JsonApiDataParser.new(
        data:             load_json(name),
        schema:           lookup("#{name}.schema"),
        schema_options:   execute_options(lookup("#{name}.options")),
        included_schemas: lookup("#{name}.included")
      ).run
    end

    def load_json(name)
      begin
        MultiJson.load(multipart_file(name).read)
      rescue MultiJson::ParseError
        raise ExternalArgumentError, multipart_file: 'invalid'
      end
    end

    def multipart_file(name)
      params[name.to_s][:tempfile]
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
