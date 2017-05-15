# frozen_string_literal: true

module RequestHandler
  module Helper
    # extracted out of active_support
    # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/hash/keys.rb#L143
    def deep_transform_keys_in_object(object, &block)
      case object
      when Hash
        object.each_with_object({}) do |(key, value), result|
          result[yield(key)] = deep_transform_keys_in_object(value, &block)
        end
      when Array
        object.map { |e| deep_transform_keys_in_object(e, &block) }
      else
        object
      end
    end
    module_function :deep_transform_keys_in_object
  end
end
