# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/option_handler.rb"
describe Dry::RequestHandler::OptionHandler do
  it "fails if params is nil" do
    expect { described_class.new(params: nil, allowed_option_types: {}) }.to raise_error(ArgumentError)
  end
end
