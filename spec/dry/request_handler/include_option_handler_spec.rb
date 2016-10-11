# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/include_option_handler"
shared_examples "proccesses the include options correctly" do
  it "it returns an array of include options" do
    handler = described_class.new(params:               params,
                                  allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    expect(handler.run).to eq output
  end
end
describe Dry::RequestHandler::IncludeOptionHandler do
  # return the right hash when the option is allowed
  it_behaves_like "proccesses the include options correctly" do
    let(:params) { { "include" => "user,email" } }
    let(:output) { [:user, :email] }
  end

  # returns an empty array when no include options are specified
  it_behaves_like "proccesses the include options correctly" do
    let(:params) { { "include" => "" } }
    let(:output) { [] }
  end

  # return an empty array if the include param is not set
  it_behaves_like "proccesses the include options correctly" do
    let(:params) { {} }
    let(:output) { [] }
  end

  it "raises a contraint error if the inlcude options contain a space" do
    params = { "include" => "user, email" }
    handler = described_class.new(params:               params,
                                  allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    expect { handler.run }.to raise_error(ArgumentError)
  end

  it "raises a contraint error if the option is not allowed" do
    params = { "include" => "user,password" }
    handler = described_class.new(params:               params,
                                  allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    expect { handler.run }.to raise_error(Dry::Types::ConstraintError)
  end
end
