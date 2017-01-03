# frozen_string_literal: true
require "spec_helper"
describe Dry::RequestHandler do
  context "HeaderHandler" do
    let(:testclass) do
      Class.new(Dry::RequestHandler::Base) do
        def to_dto
          OpenStruct.new(
            headers: headers
          )
        end
      end
    end
    it "raises a MissingArgumentError if the headers are not set" do
      request = build_mock_request(params: {}, headers: nil, body: "")
      testhandler = testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
    end
    it "works if the headers are set corectly" do
      request = build_mock_request(params: {}, headers: {
                                     "HTTP_AUTH" => "some.app.key",
                                     "ACCEPT" => "345"
                                   },
      body: "")
      testhandler = testclass.new(request: request)
      expect(testhandler.to_dto).to eq(OpenStruct.new(headers: { auth: "some.app.key",
                                                                 accept: "345" }))
    end
  end
end
