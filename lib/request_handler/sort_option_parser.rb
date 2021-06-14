# frozen_string_literal: true

require 'request_handler/option_parser'
require 'request_handler/error'
require 'request_handler/sort_option'
module RequestHandler
  class SortOptionParser < OptionParser
    def run
      return [] unless params.key?('sort')
      sort_options = parse_options(fetch_options)
      raise SortParamsError, [jsonapi_error('sort options must be unique')] if duplicates?(sort_options)
      sort_options
    end

    def fetch_options
      raise SortParamsError, [jsonapi_error('must not be empty')] if empty_param?('sort')
      params.fetch('sort') { '' }.split(',')
    end

    def parse_options(options)
      options.map do |option|
        name, order = parse_option(option)
        name.gsub!('.', ::RequestHandler.configuration.separator)
        allowed_option(name)
        SortOption.new(name, order)
      end
    end

    def parse_option(option)
      raise SortParamsError, [jsonapi_error('must not contain spaces')] if option.include? ' '
      if option.start_with?('-')
        [option[1..-1], :desc]
      else
        [option, :asc]
      end
    end

    def allowed_option(name)
      RequestHandler.configuration.validation_engine.validate!(name, allowed_options_type).output
    rescue Validation::Error
      raise OptionNotAllowedError, [jsonapi_error("#{name} is not an allowed sort option")]
    end

    def duplicates?(options)
      !options.uniq!(&:field).nil?
    end

    private

    def jsonapi_error(detail)
      {
        code: 'INVALID_QUERY_PARAMETER',
        status: '400',
        source: { parameter: 'sort' },
        detail: detail
      }
    end
  end
end
