# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/page_handler"
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
  it "fails if page_config is set to nil" do
    expect { described_class.new(params: {}, page_config: nil) }.to raise_error(ArgumentError)
  end
  it "fails if params is set to nil" do
    expect { described_class.new(params: nil, page_config: {}) }.to raise_error(ArgumentError)
  end
  it "reads the page from the params if it is below the limit" do
    params = { "page" => {
      "posts_size"   => "34",
      "posts_number" => "2",
      "users_size"   => "25",
      "users_number" => "2"
    } }
    handler = described_class.new(params: params, page_config: config.lookup!("page"))
    expect(handler.run).to eq(number:       1,
                              size:         15,
                              posts_number: 2,
                              posts_size:   34,
                              users_number: 2,
                              users_size:   25)
  end
  it "sets the size to the limit if the param requests a size bigger than allowed" do
    params = { "page" => {
      "posts_size"   => "34",
      "posts_number" => "2",
      "users_size"   => "100",
      "users_number" => "2"
    } }
    handler = described_class.new(params: params, page_config: config.lookup!("page"))
    expect(handler.run).to eq(number:       1,
                              size:         15,
                              posts_number: 2,
                              posts_size:   34,
                              users_number: 2,
                              users_size:   40)
  end
  it "defaults to the default if it is not configured in the params" do
    params = { "page" => {
      "users_size"   => "40",
      "users_number" => "2"
    } }
    handler = described_class.new(params: params, page_config: config.lookup!("page"))
    expect(handler.run).to eq(number:       1,
                              size:         15,
                              posts_number: 1,
                              posts_size:   30,
                              users_number: 2,
                              users_size:   40)
  end
  it "raises an ArgumentError if a number is set to a non integer string" do
    params = { "page" => {
      "users_size"   => "40",
      "users_number" => "asdf"
    } }
    handler = described_class.new(params: params, page_config: config.lookup!("page"))
    expect { handler.run }.to raise_error(ArgumentError)
  end
  it "raises an ArgumentError if a number is set to a negative string" do
    params = { "page" => {
      "users_size"   => "40",
      "users_number" => "-20"
    } }
    handler = described_class.new(params: params, page_config: config.lookup!("page"))
    expect { handler.run }.to raise_error(ArgumentError)
  end

  it "defaults to the default if the size is not a valid integer string" do
    # TODO: Ask ANE about the wanted behaviour in this case
    params = { "page" => {
      "users_size"   => "asdf",
      "users_number" => "2"
    } }
    handler = described_class.new(params: params, page_config: config.lookup!("page"))
    expect(handler.run).to eq(number:       1,
                              size:         15,
                              posts_number: 1,
                              posts_size:   30,
                              users_number: 2,
                              users_size:   20)
  end
end
