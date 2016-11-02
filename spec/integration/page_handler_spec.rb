# frozen_string_literal: true
require "spec_helper"
describe Dry::RequestHandler do
  context "PageHandler" do
    context "invalid settings" do
      let(:testclass) do
        Class.new(Dry::RequestHandler::Base) do
          options do
            page do
              max_size "foo"
              default_size "bar"
            end
          end
          def to_dto
            OpenStruct.new(
              page:  page_params
            )
          end
        end
      end
      it "raises an ExternalArgumentError for invalid page options" do
        request = build_mock_request(params: {}, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::ExternalArgumentError)
      end
    end
    context "valid settings" do
      let(:testclass) do
        Class.new(Dry::RequestHandler::Base) do
          options do
            page do
              max_size 100
              default_size 50
            end
          end
          def to_dto
            OpenStruct.new(
              page:  page_params
            )
          end
        end
      end
      it "raises an MissingArgumentError if params is nil" do
        request = build_mock_request(params: nil, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
      end
      it "works for valid data and valid options" do
        request = build_mock_request(params:  {
                                       "page" => {
                                         "size"   => "500",
                                         "number" => "2"
                                       }
                                     },
                                     headers: {},
                                     body:    "")
        testhandler = testclass.new(request: request)
        expect(testhandler.to_dto).to eq(OpenStruct.new(page: { number: 2, size: 100 }))
      end
    end
    context "valid settings with missing parts" do
      let(:testclass) do
        Class.new(Dry::RequestHandler::Base) do
          options do
            page do
            end
          end
          def to_dto
            OpenStruct.new(
              page:  page_params
            )
          end
        end
      end
      it "raises an NoConfigAvailableError if there is no way to determine the size" do
        request = build_mock_request(params: {}, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::NoConfigAvailableError)
      end
    end
  end
end
