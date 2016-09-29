# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/base"
describe Dry::RequestHandler::Base do
  let(:params) do {
      "url_filter" => "bar"
    }
  end
  let(:request) do
    instance_double("Rack::Request",
                    params: params,
                    env:    {},
                    body:   StringIO.new("body"))
  end
  it "passes the right arguments with a proc" do
    testclass = Class.new(described_class) do
                  options do
                    filter do
                      schema "filter_schema"
                      additional_url_filter "url_filter"
                      options nil
                    end
                  end
                end
    expect(Dry::RequestHandler::FilterHandler).to receive(:initialize).with(params:                params,
                                                                            schema:                "filter_schema",
                                                                            additional_url_filter: "url_filter",
                                                                            schema_options:        { query_id: 1 })
    testclass.new(request: request).filter_params
  end

  it "passes the right arguments with nil" do
    testclass = Class.new(described_class) do
                  options do
                    filter do
                      schema "filter_schema"
                      additional_url_filter "url_filter"
                      options nil
                    end
                  end
                end
    expect(Dry::RequestHandler::FilterHandler).to receive(:initialize).with(params:                params,
                                                                            schema:                "filter_schema",
                                                                            additional_url_filter: "url_filter",
                                                                            schema_options:        {})
    testclass.new(request: request).filter_params
  end
end
