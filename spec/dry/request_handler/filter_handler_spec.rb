# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/filter_handler"
describe Dry::RequestHandler::FilterHandler do
  it "generates the right output with one normal filter" do
    params = { "filter" => {
      "name" => "foo"
    } }
    schema = Dry::Validation.Schema do
      required("name").filled
    end
    output = {
      "name" => "foo"
    }
    handler = described_class.new(schema: schema, params: params, additional_url_filter: {})
    expect(handler.run).to eq(output)
  end
  it "generates the right output with one additional_url_filter" do
    params = {
      "name" => "foo"
    }
    additional_url_filter = ["name"]
    schema = Dry::Validation.Schema do
      required("name").filled
    end
    output = {
      "name" => "foo"
    }
    handler = described_class.new(schema: schema, params: params, additional_url_filter: additional_url_filter)
    expect(handler.run).to eq(output)
  end
  it "generates the right output with one additional_url_filter and one normal filter" do
    params = {
      "name"   => "foo",
      "filter" => {
        "test" => "bar"
      }
    }
    additional_url_filter = ["name"]
    schema = Dry::Validation.Schema do
      required("name").filled
      required("test").filled
    end
    output = {
      "name" => "foo",
      "test" => "bar"
    }
    handler = described_class.new(schema: schema, params: params, additional_url_filter: additional_url_filter)
    expect(handler.run).to eq(output)
  end
  it "outputs nothing with no filter set" do
    params = {
      "filter" => {
      }
    }
    schema = Dry::Validation.Schema do
    end
    output = {
    }
    handler = described_class.new(schema: schema, params: params, additional_url_filter: [])
    expect(handler.run).to eq(output)
  end
end
