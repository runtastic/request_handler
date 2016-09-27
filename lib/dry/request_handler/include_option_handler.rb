# frozen_string_literal: true
require "dry/request_handler/option_handler"
module Dry
  module RequestHandler
    class IncludeOptionHandler < OptionHandler
      def run
        params.fetch("include") { "" }.split(",").map do |option|
          allowed_options_type.call(option) if allowed_options_type
          option.to_sym
        end
      end
    end
  end
end
