# frozen_string_literal: true

require 'request_handler/concerns/config_helper'

module RequestHandler
  class BaseParser
    include RequestHandler::Concerns::ConfigHelper
  end
end
