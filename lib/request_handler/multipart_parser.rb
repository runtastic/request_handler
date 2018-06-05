# frozen_string_literal: true

require 'request_handler/error'
require 'request_handler/schema_parser'
require 'request_handler/error'
require 'request_handler/json_api_document_parser'
require 'request_handler/sidecar_parser'

module RequestHandler
  class MultipartsParser
    def initialize(request:, multipart_config:)
      @request = request
      @params = request.params
      @multipart_config = multipart_config
      missing_arguments = []
      missing_arguments << { multipart_config: 'is missing' } if multipart_config.nil?
      raise MissingArgumentError, missing_arguments unless missing_arguments.empty?
    end

    def run
      multipart_config.each_with_object({}) do |(name, config), memo|
        raise MultipartParamsError, multipart: "#{name} missing" if config[:required] && !params.key?(name.to_s)
        next if params[name.to_s].nil?
        memo[name] = parse_part(name.to_s)
      end
    end

    private

    def parse_part(name)
      params[name].fetch(:tempfile) { raise MultipartParamsError, multipart_file: 'missing' }
      if lookup("#{name}.schema")
        parse_data(name)
      else
        params[name]
      end
    end

    def parse_data(name)
      data = load_json(name)
      parser = jsonapi?(name) ? JsonApiDocumentParser : SidecarParser
      parser.new(
        document:         data,
        schema:           lookup("#{name}.schema"),
        schema_options:   execute_options(lookup("#{name}.options"))
      ).run
    end

    def jsonapi?(name)
      request.params[name][:type] == 'application/vnd.api+json'
    end

    def load_json(name)
      file = multipart_file(name)
      file.rewind
      file = file.read
      MultiJson.load(file)
    rescue MultiJson::ParseError
      raise MultipartParamsError, multipart_file: 'invalid JSON'
    end

    def multipart_file(name)
      params[name][:tempfile]
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
