# frozen_string_literal: true
require "spec_helper"
describe Dry::RequestHandler do
  context "Option Handler" do
    context "IncludeOptionHandler" do
      let(:testclass) do
        Class.new(Dry::RequestHandler::Base) do
          options do
            include_options do
              allowed Dry::Types["strict.string"].enum("user", "groups")
              defaults [:foo, :bar]
            end
          end
          def to_dto
            OpenStruct.new(
              include: include_params
            )
          end
        end
      end
      it "raises an OptionNotAllowedError if there is a include query that is not allowed" do
        request = build_mock_request(params: { "include" => "foo,bar" }, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::OptionNotAllowedError)
      end
      it "raises an ExternalArgumentError if the query parameter contains as space" do
        request = build_mock_request(params: { "include" => "user, groups" }, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::ExternalArgumentError)
      end
      it "raises a InternalArgumentError if params is set to nil" do
        request = build_mock_request(params: nil, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
      end
      it "raises a ExternalArgumentError if params is no Hash" do
        request = build_mock_request(params: "Foo", headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::ExternalArgumentError)
      end
      it "works for valid paramaters and settings" do
        request = build_mock_request(params: { "include" => "user" }, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect(testhandler.to_dto).to eq(OpenStruct.new(include: [:foo, :bar, :user]))
      end
    end
    context "SortOptionHandler" do
      let(:testclass) do
        Class.new(Dry::RequestHandler::Base) do
          options do
            sort_options do
              allowed Dry::Types["strict.string"].enum("name", "age")
            end
          end
          def to_dto
            OpenStruct.new(
              sort: sort_params
            )
          end
        end
      end
      it "raises an OptionNotAllowedError if there is a sort query that is not allowed" do
        request = build_mock_request(params: { "sort" => "foo,bar" }, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::OptionNotAllowedError)
      end
      it "raises an ExternalArgumentError if the query parameter contains as space" do
        request = build_mock_request(params: { "sort" => "name, age" }, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::ExternalArgumentError)
      end
      it "raises an MissingArgumentError if params is set to nil" do
        request = build_mock_request(params: nil, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
      end
      it "raises an ExternalArgumentError if params is not a Hash" do
        request = build_mock_request(params: "Foo", headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::ExternalArgumentError)
      end
      it "works for valid paramaters and settings" do
        request = build_mock_request(params: { "sort" => "-name" }, headers: {}, body: "")
        testhandler = testclass.new(request: request)
        expect(testhandler.to_dto)
          .to eq(OpenStruct.new(sort: [Dry::RequestHandler::SortOption.new("name", :desc)]))
      end
    end
  end
end
