# frozen_string_literal: true

require 'request_handler/option_parser'
require 'request_handler/error'
module RequestHandler
  class IncludeOptionParser < OptionParser
    def run
      return [] unless params.key?('include')
      options = fetch_options
      raise_error('INVALID_QUERY_PARAMETER', 'must not contain a space') if options.include?(' ')
      allowed_options(options.split(','))
    end

    def allowed_options(options)
      options.map do |option|
        option.gsub!('.', ::RequestHandler.configuration.separator)
        begin
          RequestHandler.configuration.validation_engine.validate!(option, allowed_options_type).output.to_sym
        rescue Validation::Error
          raise_error('OPTION_NOT_ALLOWED', "#{option} is not an allowed include option", OptionNotAllowedError)
        end
      end
    end

    def fetch_options
      raise_error('INVALID_QUERY_PARAMETER', 'must not be empty') if empty_param?('include')
      params.fetch('include') { '' }
    end

    private

    def raise_error(code, detail, error_klass = IncludeParamsError)
      raise error_klass, [
        {
          status: '400',
          code:   code,
          detail: detail,
          source: { parameter: 'include' }
        }
      ]
    end
  end
end
