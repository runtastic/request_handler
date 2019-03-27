# frozen_string_literal: true

require 'request_handler/option_parser'
require 'request_handler/error'
module RequestHandler
  class IncludeOptionParser < OptionParser
    def run
      return [] unless params.key?('include')
      options = fetch_options
      raise IncludeParamsError, include: 'must not contain a space' if options.include? ' '
      allowed_options(options.split(','))
    end

    def allowed_options(options)
      options.map do |option|
        option.gsub!('.', ::RequestHandler.separator)
        begin
          RequestHandler.engine.validate!(option, allowed_options_type).output.to_sym
        rescue Validation::Error
          raise OptionNotAllowedError, option.to_sym => 'is not an allowed include option'
        end
      end
    end

    def fetch_options
      raise IncludeParamsError, include_options: 'query paramter must not be empty' if empty_param?('include')
      params.fetch('include') { '' }
    end
  end
end
