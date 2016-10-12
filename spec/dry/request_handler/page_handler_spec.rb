# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/page_handler"
shared_examples "uses the right values for page and size" do
  it "uses the value from the params if its within the limits" do
    handler = Dry::RequestHandler::PageHandler.new(params: params, page_config: config.lookup!("page"))
    expect(handler.run).to eq(output)
  end
end
shared_examples "handles invalid inputs correctly" do
  it "raises the an ArgumentError error for an invalid input" do
    handler = Dry::RequestHandler::PageHandler.new(params: params, page_config: config.lookup!("page"))
    expect { handler.run }.to raise_error(ArgumentError)
  end
end
describe Dry::RequestHandler::PageHandler do
  let(:config) do
    Confstruct::Configuration.new do
      page do
        default_size 15
        max_size 50

        posts do
          default_size 30
          max_size 50
        end

        users do
          default_size 20
          max_size 40
        end
      end
    end
  end
  # reads the size from the params if it is below the limit
  it_behaves_like "uses the right values for page and size" do
    let(:params) do
      {
        "page" => {
          "posts_size"   => "34",
          "posts_number" => "2",
          "users_size"   => "25",
          "users_number" => "2"
        }
      }
    end
    let(:output) do
      {
        number:       1,
        size:         15,
        posts_number: 2,
        posts_size:   34,
        users_number: 2,
        users_size:   25
      }
    end
  end

  # sets the size to the limit if the param requests a size bigger than allowed
  it_behaves_like "uses the right values for page and size" do
    let(:params) do
      {
        "page" => {
          "posts_size"   => "34",
          "posts_number" => "2",
          "users_size"   => "100",
          "users_number" => "2"
        }
      }
    end
    let(:output) do
      {
        number:       1,
        size:         15,
        posts_number: 2,
        posts_size:   34,
        users_number: 2,
        users_size:   40
      }
    end
  end
  # defaults to the default if it is not configured in the params
  it_behaves_like "uses the right values for page and size" do
    let(:params) do
      { "page" => {
        "users_size"   => "40",
        "users_number" => "2"
      } }
    end
    let(:output) do
      { number:       1,
        size:         15,
        posts_number: 1,
        posts_size:   30,
        users_number: 2,
        users_size:   40 }
    end
  end

  # raises an ArgumentError if a number is set to a non integer string
  it_behaves_like "handles invalid inputs correctly" do
    let(:params) do
      { "page" => {
        "users_size"   => "40",
        "users_number" => "asdf"
      } }
    end
  end

  # raises an ArgumentError if a number is set to a negative string
  it_behaves_like "handles invalid inputs correctly" do
    let(:params) do
      { "page" => {
        "users_size"   => "40",
        "users_number" => "-20"
      } }
    end
  end

  # raises an ArgumentError if a size is set to a negative string
  it_behaves_like "handles invalid inputs correctly" do
    let(:params) do
      { "page" => {
        "users_size"   => "-40",
        "users_number" => "20"
      } }
    end
  end

  it_behaves_like "handles invalid inputs correctly" do
    let(:params) do
      { "page" => {
        "users_size"   => "asdf",
        "users_number" => "2"
      } }
    end
  end

  it "raises an error if page config is set to nil" do
    expect { described_class.new(params: {}, page_config: nil) }.to raise_error(ArgumentError)
  end

  it "raises an error if params is set to nil" do
    expect { described_class.new(params: nil, page_config: {}) }.to raise_error(ArgumentError)
  end
end
