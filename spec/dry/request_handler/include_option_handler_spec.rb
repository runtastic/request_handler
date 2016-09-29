# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/include_option_handler"
describe Dry::RequestHandler::IncludeOptionHandler do
  it "return the right hash when the option is allowed" do
    params = { "include" => "user,email" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    expect(handler.run).to eq([:user, :email])
  end
  it "raises an contraint error if the option is not allowed" do
    params = { "include" => "user, password" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    expect { handler.run }.to raise_error(Dry::Types::ConstraintError)
  end
  it "return an empty array when no include options are specified" do
    params = { "include" => "" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    expect(handler.run).to eq([])
  end
  it "return an empty array if the include param is not set" do
    params = {}
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    expect(handler.run).to eq([])
  end
end
