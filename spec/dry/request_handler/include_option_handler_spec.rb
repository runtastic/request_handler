# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/include_option_handler"
describe Dry::RequestHandler::IncludeOptionHandler do
  shared_examples "proccesses valid options correctly" do
    it "it returns an array of include options" do
      handler = described_class.new(params:               params,
                                    allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
      expect(handler.run).to eq output
    end
  end
  shared_examples "proccesses invalid options correctly" do
    it "raises an error if the include options are invalid" do
      handler = described_class.new(params:               params,
                                    allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
      expect { handler.run }.to raise_error(error)
    end
  end
  context "option is allowed" do
    let(:params) { { "include" => "user,email" } }
    let(:output) { [:user, :email] }
    it_behaves_like "proccesses valid options correctly"
  end

  context "include param is not set" do
    let(:params) { {} }
    let(:output) { [] }
    it_behaves_like "proccesses valid options correctly"
  end

  context "no include options are specified" do
    let(:params) { { "include" => "" } }
    let(:output) { [] }
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    it_behaves_like "proccesses invalid options correctly"
  end

  context "options contain a space" do
    let(:params) { { "include" => "user, email" } }
    let(:handler) do
      described_class.new(params:               params,
                          allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    end
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    it_behaves_like "proccesses invalid options correctly"
  end

  context "option is not allowed" do
    let(:params)  { { "include" => "user,password" } }
    let(:handler)  do
      described_class.new(params:               params,
                          allowed_options_type: Dry::Types["strict.string"].enum("user", "email"))
    end
    let(:error) { Dry::RequestHandler::OptionNotAllowedError }
    it_behaves_like "proccesses invalid options correctly"
  end
end
