# frozen_string_literal: true

require "request_handler/error"
module RequestHandler
  class OptionParser
    def initialize(params:, allowed_options_type:)
      @params = params
      @allowed_options_type = allowed_options_type
      raise InternalArgumentError.new(allowed_options_type: "must be a Schema") unless schema?
    end

    private

    def schema?
      RequestHandler.configuration.validation_engine.valid_schema?(@allowed_options_type)
    end

    def empty_param?(param)
      params.fetch(param, nil) == ""
    end
    attr_reader :params, :allowed_options_type
  end
end
