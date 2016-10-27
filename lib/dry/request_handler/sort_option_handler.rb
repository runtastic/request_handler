# frozen_string_literal: true
require "dry/request_handler/option_handler"
require "dry/request_handler/error"
module Dry
  module RequestHandler
    class SortOptionHandler < OptionHandler
      def run
        return [] unless params.key?("sort")
        sort_options = parse_options(fetch_options)
        raise InvalidArgumentError.new(sort_options: "must be unique") if duplicates?(sort_options)
        sort_options
      end

      def fetch_options
        raise InvalidArgumentError.new(sort_options: "the query paramter must not be empty") if empty_param?("sort")
        params.fetch("sort") { "" }.split(",")
      end

      def parse_options(options)
        options.map do |option|
          name, order = parse_option(option)
          allowed_option(name)
          { name.to_sym => order }
        end
      end

      def parse_option(option)
        raise InvalidArgumentError.new(sort_options: "must not contain a space") if option.include? " "
        if option.start_with?("-")
          [option[1..-1], :desc]
        else
          [option, :asc]
        end
      end

      def allowed_option(name)
        allowed_options_type.call(name) if allowed_options_type
      rescue Types::ConstraintError
        raise OptionNotAllowedError.new(name.to_sym => "is not an allowed sort option")
      end

      def duplicates?(options)
        !!options.uniq! { |hash| hash.keys[0] }
      end
    end
  end
end
