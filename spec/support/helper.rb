# frozen_string_literal: true

include RequestHandler::Concerns::ConfigHelper

def build_mock_request(params:, headers:, body: '')
  instance_double('Rack::Request', params: params, env: headers, body: StringIO.new(body))
end

def build_docile(class_name, &block)
  Docile.dsl_eval(class_name.new, &block).build
  # deep_to_h(config)
end
