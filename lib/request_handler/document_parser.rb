# frozen_string_literal: true

require "request_handler/json_api_document_parser"
require "request_handler/json_parser"

module RequestHandler
  module DocumentParser
    module_function

    def new(**args)
      type = args.delete(:type)
      type = type.to_sym unless type.nil?
      PARSER_MAPPING
        .fetch(type) { raise InternalArgumentError.new(detail: "parser for type '#{type}' not found") }
        .new(**args)
    end

    PARSER_MAPPING = {
      nil      => JsonApiDocumentParser, # no config defaults to jsonapi
      :jsonapi => JsonApiDocumentParser,
      :json    => JsonParser
    }.freeze
  end
end
