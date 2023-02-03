# frozen_string_literal: true

require "spec_helper"
require "request_handler/header_parser"
describe RequestHandler::HeaderParser do
  subject(:handler) { described_class.new(env: headers, schema: schema) }

  let(:schema) { nil }

  describe "#run" do
    subject { handler.run }

    shared_examples "fetch proper headers" do
      it "returns auth information" do
        expect(subject).to eq(expected_headers)
      end
    end

    context "when the header `Client-Id` is defined in schema" do
      let(:headers) { { "HTTP_CLIENT_ID" => "0001234" } }
      let(:schema) do
        Dry::Schema.Params do
          required(:client_id).filled(:integer)
        end
      end
      let(:expected_headers) { { client_id: 1234 } }

      it_behaves_like "fetch proper headers"

      context "when the header `Client-Id` is missing" do
        let(:headers) { {} }

        it "returns code MISSING_HEADER" do
          expect { subject }.to raise_error(RequestHandler::ExternalArgumentError) do |raised_error|
            expect(raised_error.errors).to eq(
              [
                {
                  status: "400",
                  code:   "MISSING_HEADER",
                  detail: "Client-Id is missing"
                }
              ]
            )
          end
        end
      end

      context "when the header `Client-Id` is invalid" do
        let(:headers) { { "HTTP_CLIENT_ID" => "abc" } }

        it "returns code INVALID_HEADER" do
          expect { subject }.to raise_error(RequestHandler::ExternalArgumentError) do |raised_error|
            expect(raised_error.errors).to eq(
              [
                {
                  status: "400",
                  code:   "INVALID_HEADER",
                  detail: "Client-Id must be an integer"
                }
              ]
            )
          end
        end
      end
    end

    context "only fetches the headers from the env" do
      let(:headers) do
        {
          "HTTP_USER_ID" => "user1",
          "NOT_A_HEADER" => "not shown"
        }
      end
      let(:expected_headers) do
        {
          user_id: "user1"
        }
      end

      it_behaves_like "fetch proper headers"
    end

    context "converts the headers into lowercase without the http_ prefix" do
      let(:headers) do
        {
          "HTTP_USER_ID"     => "user1",
          "HTTP_NOSNAKECASE" => "no snake case"
        }
      end
      let(:expected_headers) do
        {
          user_id:     "user1",
          nosnakecase: "no snake case"
        }
      end

      it_behaves_like "fetch proper headers"
    end
  end

  describe ".new" do
    subject { described_class.new(env: nil) }

    it "raises an error if the headers are nil" do
      expect { subject }.to raise_error(RequestHandler::MissingArgumentError)
    end
  end
end
