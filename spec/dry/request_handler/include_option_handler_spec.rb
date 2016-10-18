# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/include_option_handler"
describe Dry::RequestHandler::IncludeOptionHandler do
  shared_examples "proccesses the include options correctly" do
    it "it returns an array of include options" do
      handler = described_class.new(params:               params,
                                    allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
      expect(handler.run).to eq output
    end
  end

  context "option is allowed" do
    let(:params) { { "include" => "user,email" } }
    let(:output) { [:user, :email] }
    it_behaves_like "proccesses the include options correctly"
  end

  context "no include options are specified" do
    let(:params) { { "include" => "" } }
    let(:output) { [] }
    it_behaves_like "proccesses the include options correctly"
  end

  context "include param is not set" do
    let(:params) { {} }
    let(:output) { [] }
    it_behaves_like "proccesses the include options correctly"
  end

  it "raises a contraint error if the inlcude options contain a space" do
    params = { "include" => "user, email" }
    handler = described_class.new(params:               params,
                                  allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    expect { handler.run }.to raise_error(Dry::RequestHandler::InvalidArgumentError)
  end

  it "raises a contraint error if the option is not allowed" do
    params = { "include" => "user,password" }
    handler = described_class.new(params:               params,
                                  allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    expect { handler.run }.to raise_error(Dry::RequestHandler::OptionNotAllowedError)
  end
end
