# frozen_string_literal: true
def build_mock_request(params:, headers:, body: "")
  instance_double("Rack::Request", params: params, env: headers, body: StringIO.new(body))
end
