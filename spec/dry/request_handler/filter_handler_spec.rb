# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/filter_handler"
describe Dry::RequestHandler::FilterHandler do
  shared_examples "proccesses the filters correctly" do
    it "outputs the filters in a flat way" do
      handler = described_class.new(schema: schema, params: params, additional_url_filter: additional_url_filter)
      expect(handler.run).to eq(output)
    end
  end

  let(:additional_url_filter) { [] }

  context "one normal filter" do
    let(:params) do
      { "filter" => { "name" => "foo" } }
    end
    let(:schema) do
      Dry::Validation.Schema do
        required("name").filled
      end
    end
    let(:output)  do
      { "name" => "foo" }
    end
    it_behaves_like "proccesses the filters correctly"
  end

  context "one additional_url_filter" do
    let(:params) do
      {
        "name" => "foo"
      }
    end
    let(:additional_url_filter) { ["name"] }
    let(:schema) do
      Dry::Validation.Schema do
        required("name").filled
      end
    end
    let(:output) do
      {
        "name" => "foo"
      }
    end
    it_behaves_like "proccesses the filters correctly"
  end

  context "one additional_url_filter and one normal filter" do
    let(:params) do
      {
        "name"   => "foo",
        "filter" => {
          "test" => "bar"
        }
      }
    end
    let(:additional_url_filter) { ["name"] }
    let(:schema) do
      Dry::Validation.Schema do
        required("name").filled
        required("test").filled
      end end
    let(:output) do
      {
        "name" => "foo",
        "test" => "bar"
      }
    end
    it_behaves_like "proccesses the filters correctly"
  end

  context "no filter set" do
    let(:params) do
      {
        "filter" => {
        }
      }
    end
    let(:schema) { Dry::Validation.Schema {} }
    let(:output) { {} }
    it_behaves_like "proccesses the filters correctly"
  end

  context "without the filter hash" do
    let(:params) do
      {
      }
    end
    let(:schema) { Dry::Validation.Schema {} }
    let(:output) { {} }
    it_behaves_like "proccesses the filters correctly"
  end

  it "fails for a filter that was set twice" do
    params =
      {
        "name"   => "foo",
        "filter" => {
          "name" => "bar"
        }
      }
    additional_url_filter = ["name"]
    schema = Dry::Validation.Schema do
      required("name").filled
    end
    expect { described_class.new(schema: schema, params: params, additional_url_filter: additional_url_filter) }
      .to raise_error(Dry::RequestHandler::InvalidArgumentError)
  end

  it "fails if params.filter is not a Hash" do
    params =
      {
        "filter" => "nope"
      }
    schema = Dry::Validation.Schema do
      required("name").filled
    end
    expect { described_class.new(schema: schema, params: params, additional_url_filter: additional_url_filter) }
      .to raise_error(Dry::RequestHandler::WrongArgumentTypeError)
  end
end
