# frozen_string_literal: true

module RequestHandler
  class BaseError < StandardError
    attr_reader :errors
    def initialize(errors)
      @errors = errors
      super(message)
    end

    def message
      errors.map do |key, value|
        "#{key}: #{value}"
      end.join(', ')
    end
  end
  class InternalBaseError < BaseError
  end
  class ExternalBaseError < BaseError
  end
  class JsonApiError < ExternalBaseError
    def message
      @errors.map do |error|
        "#{error[:code]}: #{error[:source]} #{error[:detail]}"
      end.join(',\n')
    end

    def errors
      RequestHandler.configuration.raise_jsonapi_errors ? @errors : []
    end
  end
  class MissingArgumentError < InternalBaseError
  end
  class ExternalArgumentError < JsonApiError
  end
  class InternalArgumentError < InternalBaseError
  end
  class SchemaValidationError < JsonApiError
  end
  class OptionNotAllowedError < JsonApiError
  end
  class NoConfigAvailableError < InternalBaseError
  end

  class BodyParamsError < ExternalArgumentError
  end
  class FieldsetsParamsError < ExternalArgumentError
  end
  class FilterParamsError < ExternalArgumentError
  end
  class IncludeParamsError < ExternalArgumentError
  end
  class PageParamsError < ExternalArgumentError
  end
  class SortParamsError < ExternalArgumentError
  end
  class MultipartParamsError < ExternalArgumentError
  end
end
