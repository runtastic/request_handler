# frozen_string_literal: true
require "dry/request_handler/option_handler"
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class SortOptionHandler < OptionHandler
      def run
        sort_options = params.fetch("sort") { "" }.split(",").map do |option|
          name, order = parse_options(option)
          allowed_option(name)
          { name.to_sym => order }
        end
        unless sort_options.uniq! { |hash| hash.keys[0] }.nil?
          raise InvalidArgumentError.new("sort_options", "not unique")
        end
        sort_options
      end

      def parse_options(option)
        raise InvalidArgumentError.new("sort_options", "contains a space") if option.include? " "
        if option.start_with?("-")
          [option[1..-1], :desc]
        else
          [option, :asc]
        end
      end

      def allowed_option(name)
        allowed_options_type.call(name) if allowed_options_type
      rescue Types::ConstraintError
        raise OptionNotAllowedError.new(name)
      end
    end
  end
end
