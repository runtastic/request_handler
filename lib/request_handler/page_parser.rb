# frozen_string_literal: true

require 'request_handler/error'
module RequestHandler
  class PageParser
    def initialize(params:, page_config:)
      missing_arguments = []
      missing_arguments << { params: 'is missing' } if params.nil?
      missing_arguments << { page_config: 'is missing' } if page_config.nil?
      raise MissingArgumentError, missing_arguments unless missing_arguments.empty?
      @page_options = params.fetch('page') { {} }
      raise PageParamsError, page: 'must be a Hash' unless @page_options.is_a?(Hash)
      @config = page_config
    end

    def run
      base = { number: extract_number, size: extract_size }
      cfg = config.keys.reduce(base) do |memo, key|
        next memo if TOP_LEVEL_PAGE_KEYS.include?(key)
        memo.merge!("#{key}#{::RequestHandler.separator}number".to_sym => extract_number(prefix: key),
                    "#{key}#{::RequestHandler.separator}size".to_sym   => extract_size(prefix: key))
      end
      check_for_missing_options(cfg)
      cfg
    end

    private

    TOP_LEVEL_PAGE_KEYS = Set.new(%i[default_size max_size])
    attr_reader :page_options, :config

    def check_for_missing_options(config)
      missing_arguments = page_options.keys - config.keys.map(&:to_s)
      return if missing_arguments.empty?
      missing_arguments.map! { |e| e.gsub(::RequestHandler.separator, '.') }
      warn 'client sent unknown option ' + missing_arguments.to_s unless missing_arguments.empty?
    end

    def extract_number(prefix: nil)
      number_string = lookup_nested_params_key('number', prefix) || 1
      check_int(string: number_string, param: "#{prefix}.number")
    end

    def extract_size(prefix: nil)
      size = fetch_and_check_size(prefix)
      default_size = fetch_and_check_default_size(prefix)
      return default_size if size.nil?
      apply_max_size_constraint(size, prefix)
    end

    def fetch_and_check_default_size(prefix)
      default_size = lookup_nested_config_key('default_size', prefix)
      raise_no_default_size(prefix) if default_size.nil?
      raise_not_positive(prefix, 'size') unless default_size.is_a?(Integer) && default_size > 0
      default_size
    end

    def fetch_and_check_size(prefix)
      size_string = lookup_nested_params_key('size', prefix)
      return nil if size_string.nil?
      check_int(string: size_string, param: "#{prefix}.size") unless size_string.nil?
    end

    def check_int(string:, param:)
      output = Integer(string)
      raise_page_param_error!(param) unless output > 0
      output
    rescue ArgumentError
      raise_page_param_error!(param)
    end

    def raise_page_param_error!(param)
      raise PageParamsError, [{
        code: 'INVALID_QUERY_PARAMETER',
        status: '400',
        detail: 'must be a positive integer',
        source: { param: "page[#{param}]" }
      }]
    end

    def apply_max_size_constraint(size, prefix)
      max_size = lookup_nested_config_key('max_size', prefix)
      case max_size
      when Integer
        [max_size, size].min
      when nil
        warn "#{prefix} max_size config not set"
        size
      else
        raise_not_positive(prefix, 'max_size', ' ')
      end
    end

    def lookup_nested_config_key(key, prefix)
      key = prefix ? "#{prefix}.#{key}" : key
      config.lookup!(key)
    end

    def lookup_nested_params_key(key, prefix)
      key = prefix ? "#{prefix}#{::RequestHandler.separator}#{key}" : key
      page_options.fetch(key, nil)
    end

    def warn(message)
      ::RequestHandler.configuration.logger.warn(message)
    end

    def raise_no_default_size(prefix, sep = ::RequestHandler.separator)
      raise NoConfigAvailableError, :"#{prefix}#{sep}size" => 'has no default_size'
    end

    def raise_not_positive(prefix, key, sep = ::RequestHandler.separator)
      raise InternalArgumentError, :"#{prefix}#{sep}#{key}" => 'must be a positive Integer'
    end
  end
end
