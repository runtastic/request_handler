# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/header_handler"
describe Dry::RequestHandler::HeaderHandler do
  shared_examples "fetch proper headers" do
    it "returns auth information" do
      handler = Dry::RequestHandler::HeaderHandler.new(env: headers)
      expect(handler.run).to eq(expected_headers)
    end
  end

  context "only fetches the headers from the env" do
    let(:headers) do
      {
        "ACCEPT" => "user1",
        "NOT_A_HEADER"         => "not shown"
      }
    end
    let(:expected_headers) do
      {
        accept: "user1"
      }
    end
    it_behaves_like "fetch proper headers"
  end

  context "converts the heades into lowercase without the http_ prefix" do
    let(:headers) do
      {
        "ACCEPT" => "user1",
        "HTTP_NOSNAKECASE"     => "no snake case"
      }
    end
    let(:expected_headers) do
      {
        accept: "user1",
        nosnakecase:     "no snake case"
      }
    end
    it_behaves_like "fetch proper headers"
  end

  it "raises an error if the headers are nil" do
    expect { described_class.new(env: nil) }.to raise_error(Dry::RequestHandler::MissingArgumentError)
  end
end
