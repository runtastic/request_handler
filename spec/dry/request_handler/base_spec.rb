# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/base"

class Parent < Dry::RequestHandler::Base
  options do
    option_1 "option_1_parent"
    option_nested do
      option_2 "option_2_parent"
    end
  end
end
class Child < Parent
  options do
    option_1 "option_1_child"
    option_nested do
      option_2 "option_2_child"
    end
  end
end

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

  let(:parent) { Parent.new(request: request) }
  let(:child) { Child.new(request: request) }

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
  context "#page_params" do
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
  context "#include_params" do
    testclass = Class.new(described_class) do
      options do
        include_options do
          allowed "allowed_options"
        end
      end
    end
    it "passes the right arguments" do
      expect(Dry::RequestHandler::IncludeOptionHandler)
        .to receive(:new).with(params:               params,
                               allowed_options_type: "allowed_options").and_return(runstub)
      testclass.new(request: request).include_params
    end
  end
  context "#sort_params" do
    testclass = Class.new(described_class) do
      options do
        sort_options do
          allowed "allowed_options"
        end
      end
    end
    it "passes the right arguments" do
      expect(Dry::RequestHandler::SortOptionHandler)
        .to receive(:new).with(params:               params,
                               allowed_options_type: "allowed_options").and_return(runstub)
      testclass.new(request: request).sort_params
    end
  end
  context "#authorization_headers" do
    testclass = Class.new(described_class) do
    end
    it "passes the right arguments" do
      expect(Dry::RequestHandler::AuthorizationHandler)
        .to receive(:new).with(env: request.env).and_return(runstub)
      testclass.new(request: request).authorization_headers
    end
  end
  context "#body_params" do
    it "passes the right arguments with a proc as argument" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options(->(_handler, _request) { { body_user_id: 1 } })
          end
        end
      end
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).with(request:        request,
                               schema:         "schema",
                               schema_options: { body_user_id: 1 }).and_return(runstub)
      testclass.new(request: request).body_params
    end
    it "passes the right arguments with a hash as argument" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options(body_user_id: 1)
          end
        end
      end
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).with(request:        request,
                               schema:         "schema",
                               schema_options: { body_user_id: 1 }).and_return(runstub)
      testclass.new(request: request).body_params
    end
    it "passes the right arguments with nil as argument" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options nil
          end
        end
      end
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).with(request:        request,
                               schema:         "schema",
                               schema_options: {}).and_return(runstub)
      testclass.new(request: request).body_params
    end
  end
  context "#params" do
    it "tranforms the params dots to undescores before using them" do
      testclass = Class.new(described_class)
      request = instance_double("Rack::Request",
                                params: { "foo.bar" => "test",
                                          "nested"  => { "nested.foo.bar" => "test2" } },
                                env:    {},
                                body:   StringIO.new("body"))
      expect(testclass.new(request: request).send(:params)). to eq("foo_bar" => "test",
                                                                   "nested"  => { "nested_foo_bar" => "test2" })
    end
  end
  context "inheritance tests" do
    it "does not override the config ob the base class" do
      expect(parent.send(:config).lookup!("option_1")).to eq("option_1_parent")
    end
    it "does not override the nested config of the base class" do
      expect(parent.send(:config).lookup!("option_nested.option_2")).to eq("option_2_parent")
    end
    it "returns the right normal config for the child class" do
      expect(child.send(:config).lookup!("option_1")).to eq("option_1_child")
    end
    it "returns the right nested config for the child class" do
      expect(child.send(:config).lookup!("option_nested.option_2")).to eq("option_2_child")
    end
  end
end

# Wenn Create immer create und nicht die von update
# Vererbung übernimmt nicht überschriebene

# TODO: Übernimmt nicht überschriebene. EdgeCases?
