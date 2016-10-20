# frozen_string_literal: true
require "spec_helper"
describe Dry::RequestHandler do
  context "SchemaHandler" do
    context "BodyHandler" do
      let(:valid_body) do
        <<~JSON
      {
        "data": {
          "attributes": {
            "name": "About naming stuff and cache invalidation"
          }
        }
      }
      JSON
      end
      let(:invalid_body) do
        <<~JSON
      {
        "data": {
          "attributes": {
            "foo": "About naming stuff and cache invalidation"
          }
        }
      }
      JSON
      end
      context "valid schema" do
        let(:testclass) do
          Class.new(Dry::RequestHandler::Base) do
            options do
              body do
                schema(Dry::Validation.JSON do
                  required(:name).filled(:str?)
                end)
              end
            end
            def to_dto
              OpenStruct.new(
                body:  body_params
              )
            end
          end
        end
        it "raises a SchemaValidationError with invalid data" do
          request = build_mock_request(params: {}, headers: {}, body: invalid_body)
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::SchemaValidationError)
        end

        it "raises a MissingArgumentError with missing data" do
          request = instance_double("Rack::Request", params: {}, env: {}, body: nil)
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
        end

        it "works for valid data" do
          request = build_mock_request(params: {}, headers: {}, body: valid_body)
          testhandler = testclass.new(request: request)
          expect(testhandler.to_dto).to eq(OpenStruct.new(body: { name: "About naming stuff and cache invalidation" }))
        end
      end
      context "invalid schema" do
        let(:testclass) do
          Class.new(Dry::RequestHandler::Base) do
            options do
              body do
                schema "Foo"
              end
            end
            def to_dto
              OpenStruct.new(
                body:  body_params
              )
            end
          end
        end
        it "raises a WrongArgumentTypeError valid data" do
          request = build_mock_request(params: {}, headers: {}, body: valid_body)
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::WrongArgumentTypeError)
        end
      end
    end

    context "FilterHandler" do
      let(:valid_params) do
        {
          "filter" => {
            "name" => "foo"
          }
        }
      end
      let(:invalid_params) do
        {
          "filter" => {
            "bar" => "foo"
          }
        }
      end
      context "valid schema" do
        let(:testclass) do
          Class.new(Dry::RequestHandler::Base) do
            options do
              filter do
                schema(Dry::Validation.Form do
                  required(:name).filled(:str?)
                end)
              end
            end
            def to_dto
              OpenStruct.new(
                filter:  filter_params
              )
            end
          end
        end
        it "raises a SchemaValidationError with invalid data" do
          request = build_mock_request(params: invalid_params, headers: {}, body: "")
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::SchemaValidationError)
        end

        it "raises a MissingArgumentError with missing data" do
          request = build_mock_request(params: nil, headers: {}, body: "")
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
        end

        it "works for valid data" do
          request = build_mock_request(params: valid_params, headers: {}, body: "")
          testhandler = testclass.new(request: request)
          expect(testhandler.to_dto).to eq(OpenStruct.new(filter: { name: "foo" }))
        end
      end
      context "invalid schema" do
        let(:testclass) do
          Class.new(Dry::RequestHandler::Base) do
            options do
              filter do
                schema "Foo"
              end
            end
            def to_dto
              OpenStruct.new(
                filter:  filter_params
              )
            end
          end
        end
        it "raises a WrongArgumentTypeError with valid data" do
          request = build_mock_request(params: valid_params, headers: {}, body: "")
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::WrongArgumentTypeError)
        end
      end
    end
  end
end
