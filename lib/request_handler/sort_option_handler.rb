# frozen_string_literal: true
require 'request_handler/option_handler'
require 'request_handler/error'
require 'request_handler/sort_option'
module RequestHandler
  class SortOptionHandler < OptionHandler
    def run
      return [] unless params.key?('sort')
      sort_options = parse_options(fetch_options)
      raise ExternalArgumentError, sort_options: 'must be unique' if duplicates?(sort_options)
      sort_options
    end

    def fetch_options
      raise ExternalArgumentError, sort_options: 'the query paramter must not be empty' if empty_param?('sort')
      params.fetch('sort') { '' }.split(',')
    end

    def parse_options(options)
      options.map do |option|
        name, order = parse_option(option)
        allowed_option(name)
        SortOption.new(name, order)
      end
    end

    def parse_option(option)
      raise ExternalArgumentError, sort_options: 'must not contain a space' if option.include? ' '
      if option.start_with?('-')
        [option[1..-1], :desc]
      else
        [option, :asc]
      end
    end

    def allowed_option(name)
      allowed_options_type&.call(name)
    rescue Dry::Types::ConstraintError
      raise OptionNotAllowedError, name.to_sym => 'is not an allowed sort option'
    end

    def duplicates?(options)
      !options.uniq!(&:field).nil?
    end
  end
end
