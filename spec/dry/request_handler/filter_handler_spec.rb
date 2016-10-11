# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/filter_handler"
shared_examples "proccesses the filters correctly" do
  it "outputs the filters in a flat way" do
    handler = described_class.new(schema: schema, params: params, additional_url_filter: additional_url_filter)
    expect(handler.run).to eq(output)
  end
end
describe Dry::RequestHandler::FilterHandler do
  let(:additional_url_filter) { [] }
  # generates the right output with one normal filter
  it_behaves_like "proccesses the filters correctly" do
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
  end

  # generates the right output with one additional_url_filter
  it_behaves_like "proccesses the filters correctly" do
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
  end

  # generates the right output with one additional_url_filter and one normal filter
  it_behaves_like "proccesses the filters correctly" do
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
  end

  # outputs nothing with no filter set
  it_behaves_like "proccesses the filters correctly" do
    let(:params) do
      {
        "filter" => {
        }
      }
    end
    let(:schema) { Dry::Validation.Schema {} }
    let(:output) { {} }
  end
end
