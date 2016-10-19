# frozen_string_literal: true
require "spec_helper"

def build_mock_request(params:, headers:, body: "")
  instance_double("Rack::Request", params: params, env: headers, body: StringIO.new(body))
end

describe Dry::RequestHandler do
  context "BodyHandler" do
    let(:invalid_testclass) do
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
    let(:valid_testclass) do
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

    it "raises an WrongArgumentTypeError with an invalid schema" do
      request = build_mock_request(params: {}, headers: {}, body: valid_body)
      testhandler = invalid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::WrongArgumentTypeError)
    end

    it "raises an SchemaValidationError with a valid schema but invalid data" do
      request = build_mock_request(params: {}, headers: {}, body: invalid_body)
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::SchemaValidationError)
    end

    it "raises an MissingArgumentError with a valid schema but missing data" do
      request = instance_double("Rack::Request", params: {}, env: {}, body: nil)
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
    end

    it "works for a valid schema and valid data" do
      request = build_mock_request(params: {}, headers: {}, body: valid_body)
      testhandler = valid_testclass.new(request: request)
      expect(testhandler.to_dto).to eq(OpenStruct.new(body: { name: "About naming stuff and cache invalidation" }))
    end
  end

  context "PageHandler" do
    let(:invalid_testclass) do
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
    let(:valid_testclass) do
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
    let(:testclass_with_missing_settings) do
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
    it "raises an InvalidArgumentError for invalid page options" do
      request = build_mock_request(params: {}, headers: {}, body: "")
      testhandler = invalid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::InvalidArgumentError)
    end

    it "raises an MissingArgumentError if params is nil" do
      request = build_mock_request(params: nil, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
    end

    it "raises an NoConfigAvailableError if there is no way to determine the size" do
      request = build_mock_request(params: {}, headers: {}, body: "")
      testhandler = testclass_with_missing_settings.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::NoConfigAvailableError)
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
      testhandler = valid_testclass.new(request: request)
      expect(testhandler.to_dto).to eq(OpenStruct.new(page: { number: 2, size: 100 }))
    end
  end
  context "IncludeOptionHandler" do
    let(:valid_testclass) do
      Class.new(Dry::RequestHandler::Base) do
        options do
          include_options do
            allowed Dry::Types["strict.string"].enum("user", "groups")
          end
        end
        def to_dto
          OpenStruct.new(
            include: include_params
          )
        end
      end
    end
    it "raises an OptionNotAllowedError if there is a forbidden include query" do
      request = build_mock_request(params: { "include" => "foo,bar" }, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::OptionNotAllowedError)
    end
    it "raises an InvalidArgumentError if query parameter contains as space" do
      request = build_mock_request(params: { "include" => "user, groups" }, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::InvalidArgumentError)
    end
    it "raises an MissingArgumentError if there is params is set to nil" do
      request = build_mock_request(params: nil, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
    end
    it "raises an WrongArgumentTypeError if there is a forbidden include query" do
      request = build_mock_request(params: "Foo", headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::WrongArgumentTypeError)
    end
    it "works for valid paramaters and settings" do
      request = build_mock_request(params: { "include" => "user" }, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect(testhandler.to_dto).to eq(OpenStruct.new(include: [:user]))
    end
  end
  context "FilterHandler" do
    let(:invalid_testclass) do
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
    let(:valid_testclass) do
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

    it "raises an WrongArgumentTypeError with an invalid schema" do
      request = build_mock_request(params: valid_params, headers: {}, body: "")
      testhandler = invalid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::WrongArgumentTypeError)
    end

    it "raises an SchemaValidationError with a valid schema but invalid data" do
      request = build_mock_request(params: invalid_params, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::SchemaValidationError)
    end

    it "raises an MissingArgumentError with a valid schema but missing data" do
      request = build_mock_request(params: nil, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
    end

    it "works for a valid schema and valid data" do
      request = build_mock_request(params: valid_params, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect(testhandler.to_dto).to eq(OpenStruct.new(filter: { name: "foo" }))
    end
  end
  context "SortOptionHandler" do
    let(:valid_testclass) do
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
    it "raises an OptionNotAllowedError if there is a forbidden sort query" do
      request = build_mock_request(params: { "sort" => "foo,bar" }, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::OptionNotAllowedError)
    end
    it "raises an InvalidArgumentError if query parameter contains as space" do
      request = build_mock_request(params: { "sort" => "name, age" }, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::InvalidArgumentError)
    end
    it "raises an MissingArgumentError if there is params is set to nil" do
      request = build_mock_request(params: nil, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::MissingArgumentError)
    end
    it "raises an WrongArgumentTypeError if params is not a Hash" do
      request = build_mock_request(params: "Foo", headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::WrongArgumentTypeError)
    end
    it "works for valid paramaters and settings" do
      request = build_mock_request(params: { "sort" => "-name" }, headers: {}, body: "")
      testhandler = valid_testclass.new(request: request)
      expect(testhandler.to_dto).to eq(OpenStruct.new(sort: [{ name: :desc }]))
    end
  end
  context "AuthorizationHandler" do
    let(:testclass) do
      Class.new(Dry::RequestHandler::Base) do
        def to_dto
          OpenStruct.new(
            header: authorization_headers
          )
        end
      end
    end
    it "raises a MissingArgumentError if env not set" do
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
      expect(testhandler.to_dto).to eq(OpenStruct.new(header: { auth: "some.app.key",
                                                                accept: "345" }))
    end
  end
end
