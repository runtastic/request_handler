# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/base"
describe Dry::RequestHandler::Base do
  let(:params) do
    {
      "url_filter" => "bar"
    }
  end
  let(:request) do
    instance_double("Rack::Request",
                    params: params,
                    env:    {},
                    body:   StringIO.new("body"))
  end
  let(:runstub) { double("Handler", run: nil) }

  context "#filter_params" do
    it "passes the right arguments with a proc" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options(->(_handler, _request) { { body_user_id: 1 } })
          end
        end
      end
      expect(Dry::RequestHandler::FilterHandler)
        .to receive(:new).with(params:                params,
                               schema:                "schema",
                               additional_url_filter: "url_filter",
                               schema_options:        { body_user_id: 1 }).and_return(runstub)
      testclass.new(request: request).filter_params
    end

    it "passes the right arguments with nil" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options nil
          end
        end
      end
      expect(Dry::RequestHandler::FilterHandler)
        .to receive(:new).with(params:                params,
                               schema:                "schema",
                               additional_url_filter: "url_filter",
                               schema_options:        {}).and_return(runstub)
      testclass.new(request: request).filter_params
    end
    it "passes the right arguments a hash" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options(body_user_id: 1)
          end
        end
      end
      expect(Dry::RequestHandler::FilterHandler)
        .to receive(:new).with(params:                params,
                               schema:                "schema",
                               additional_url_filter: "url_filter",
                               schema_options:        { body_user_id: 1 }).and_return(runstub)
      testclass.new(request: request).filter_params
    end
  end
  context "include_params" do
    testclass = Class.new(described_class) do
      options do
        page do
          default_size "default_size"
        end
      end
    end
    it "passes the right arguments" do
      expect(Dry::RequestHandler::PageHandler)
        .to receive(:new).with(params:      params,
                               page_config: { default_size: "default_size" }).and_return(runstub)
      testclass.new(request: request).page_params
    end
  end
end
