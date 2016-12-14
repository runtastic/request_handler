# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/base"
describe Dry::RequestHandler do
  let(:testclass) do
    Class.new(Dry::RequestHandler::Base) do
      options do
        field_set do
          allowed do
            posts Dry::Types["strict.string"].enum("foo", "bar")
          end
          required [:posts]
        end
      end
      def to_dto
        OpenStruct.new(
          field_set: field_set_params
        )
      end
    end
  end
  it "works for a valid request" do
    request = build_mock_request(params: { "fields" => { "posts" => "foo,bar" } }, headers: nil, body: "")
    testhandler = testclass.new(request: request)
    expect(testhandler.to_dto).to eq(OpenStruct.new(field_set: { posts: [:foo, :bar] }))
  end

  it "raises an OptionNotAllowedError if the client sends a type not allowed on the server" do
    request = build_mock_request(params: { "fields" => { "photos" => "bar" } }, headers: nil, body: "")
    testhandler = testclass.new(request: request)
    expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::OptionNotAllowedError)
  end

  it "raises an OptionNotAllowedError if the client sends a value that is not allowed for a type" do
    request = build_mock_request(params: { "fields" => { "posts" => "no" } }, headers: nil, body: "")
    testhandler = testclass.new(request: request)
    expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::ExternalArgumentError)
  end
  it "raises an OptionNotAllowedError if the client sends a value that is not allowed for a type" do
    testclass.config.field_set.allowed.posts = %w(foo bar)
    request = build_mock_request(params: { "fields" => { "posts" => "foo" } }, headers: nil, body: "")
    testhandler = testclass.new(request: request)
    expect { testhandler.to_dto }.to raise_error(Dry::RequestHandler::InternalArgumentError)
  end
end
