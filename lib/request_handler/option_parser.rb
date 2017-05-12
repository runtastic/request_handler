# frozen_string_literal: true

require 'request_handler/error'
module RequestHandler
  class OptionParser
    def initialize(params:, allowed_options_type:)
      @params = params
      @allowed_options_type = allowed_options_type
      raise InternalArgumentError, allowed_options_type: 'must be a Enum' unless enum?
    end

    private

    def enum?
      @allowed_options_type.class.equal?(Dry::Types::Enum)
    end

    def empty_param?(param)
      params.fetch(param) { nil } == ''
    end
    attr_reader :params, :allowed_options_type
  end
end
