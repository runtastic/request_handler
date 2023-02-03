# frozen_string_literal: true

require "request_handler/concerns/config_helper"
require "request_handler/document_parser"
require "request_handler/error"
require "request_handler/schema_parser"

module RequestHandler
  class MultipartsParser
    include RequestHandler::Concerns::ConfigHelper

    def initialize(request:, multipart_config:)
      @request = request
      @params = request.params
      @multipart_config = multipart_config
      raise MissingArgumentError.new([{ multipart_config: "is missing" }]) if multipart_config.nil?
    end

    def run
      deep_to_h(multipart_config).each_with_object({}) do |(name, config), indexed_parts|
        validate_presence!(name) if config[:required]
        next if params[name.to_s].nil?

        indexed_parts[name] = parse_part(name.to_s)
      end
    end

    private

    def validate_presence!(sidecar_name)
      return if params.key?(sidecar_name.to_s)

      raise multipart_params_error("missing required sidecar resource: #{sidecar_name}")
    end

    def multipart_params_error(detail = "")
      MultipartParamsError.new([{
                                 status: "400",
                                 code:   "INVALID_MULTIPART_REQUEST",
                                 detail: detail
                               }])
    end

    def parse_part(name)
      params[name].fetch(:tempfile) { raise MultipartParamsError.new([{ multipart_file: "missing" }]) }
      if lookup(multipart_config, "#{name}.schema")
        parse_data(name)
      else
        params[name]
      end
    end

    def parse_data(name)
      data = load_json(name)
      type = lookup(multipart_config, "#{name}.type")
      DocumentParser.new(
        type:           type,
        document:       data,
        schema:         lookup(multipart_config, "#{name}.schema"),
        schema_options: execute_options(lookup(multipart_config, "#{name}.options"))
      ).run
    end

    def load_json(name)
      file = multipart_file(name)
      file.rewind
      file = file.read
      MultiJson.load(file)
    rescue MultiJson::ParseError
      raise multipart_params_error("sidecar resource is not valid JSON")
    end

    def multipart_file(name)
      params[name][:tempfile]
    end

    def execute_options(options)
      return {} if options.nil?
      return options unless options.respond_to?(:call)

      options.call(self, request)
    end

    attr_reader :params, :request, :multipart_config
  end
end
