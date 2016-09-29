# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/body_handler"
describe Dry::RequestHandler::BodyHandler do
  def build_mock_request(params:, headers:, body: "")
    # TODO: check if this double is close enough to a real Rack::Request
    instance_double("Rack::Request", params: params, env: headers, body: StringIO.new(body))
  end
  schema = Dry::Validation.JSON {}
  it "flattens the body correctly with one relationship" do
    raw_body = <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          },
          "relationships":{
            "category": {
                "data":
                  { "id": "54", "type": "category" }
            }
          }
        }
      }
    JSON
    wanted_result = { id:         "fer342ref",
                      type:       "post",
                      user_id:    "awesome_user_id",
                      name:       "About naming stuff and cache invalidation",
                      publish_on: Time.iso8601("2016-09-26T12:23:55Z"),
                      category:   {
                        id:   "54",
                        type: "category"
                      } }
    schema = Dry::Validation.JSON do
      required(:id).filled(:str?)
      required(:type).value(eql?: "post")
      required(:user_id).filled(:str?)
      required(:name).filled(:str?)
      optional(:publish_on).filled(:time?)

      required(:category).schema do
        required(:id).filled(:str?)
        required(:type).value(eql?: "category")
      end
    end
    test = described_class.new(schema: schema, request: build_mock_request(params: {}, headers: {}, body: raw_body))
    expect(test.run).to eq(wanted_result)
  end
  it "flattens the body correctly with multiple relationships" do
    raw_body = <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          },
          "relationships":{
            "category": {
                "data":
                  { "id": "54", "type": "category" }
            },
            "comments": {
                "data":
                  { "id": "1", "type": "comment" }
            }
          }
        }
      }
    JSON
    wanted_result = { id:         "fer342ref",
                      type:       "post",
                      user_id:    "awesome_user_id",
                      name:       "About naming stuff and cache invalidation",
                      publish_on: Time.iso8601("2016-09-26T12:23:55Z"),
                      category:   {
                        id:   "54",
                        type: "category"
                      },
                      comments:   {
                        id:   "1",
                        type: "comment"
                      } }
    schema = Dry::Validation.JSON do
      required(:id).filled(:str?)
      required(:type).value(eql?: "post")
      required(:user_id).filled(:str?)
      required(:name).filled(:str?)
      optional(:publish_on).filled(:time?)

      required(:category).schema do
        required(:id).filled(:str?)
        required(:type).value(eql?: "category")
      end
      required(:comments).schema do
        required(:id).filled(:str?)
        required(:type).value(eql?: "comment")
      end
    end
    test = described_class.new(schema: schema, request: build_mock_request(params: {}, headers: {}, body: raw_body))
    expect(test.run).to eq(wanted_result)
  end
  it "flattens the body correctly without relationships" do
    raw_body = <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          }
        }
      }
    JSON
    wanted_result = { id:         "fer342ref",
                      type:       "post",
                      user_id:    "awesome_user_id",
                      name:       "About naming stuff and cache invalidation",
                      publish_on: Time.iso8601("2016-09-26T12:23:55Z") }
    schema = Dry::Validation.JSON do
      required(:id).filled(:str?)
      required(:type).value(eql?: "post")
      required(:user_id).filled(:str?)
      required(:name).filled(:str?)
      optional(:publish_on).filled(:time?)
    end
    test = described_class.new(schema: schema, request: build_mock_request(params: {}, headers: {}, body: raw_body))
    expect(test.run).to eq(wanted_result)
  end
  it "flattens the body correctly without attributes" do
    raw_body = <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "relationships":{
            "category": {
                "data":
                  { "id": "54", "type": "category" }
            }
          }
        }
      }
    JSON
    wanted_result = { id:       "fer342ref",
                      type:     "post",
                      category: {
                        id:   "54",
                        type: "category"
                      } }
    schema = Dry::Validation.JSON do
      required(:id).filled(:str?)
      required(:type).value(eql?: "post")

      required(:category).schema do
        required(:id).filled(:str?)
        required(:type).value(eql?: "category")
      end
    end
    test = described_class.new(schema: schema, request: build_mock_request(params: {}, headers: {}, body: raw_body))
    expect(test.run).to eq(wanted_result)
  end

  it "fails if the request is nil" do
    expect { described_class.new(schema: schema, request: nil) }.to raise_error(ArgumentError)
  end

  it "fails if the request body is nil" do
    expect do
      described_class.new(schema:  schema,
                          request: instance_double("Rack::Request", params: {}, env: {}, body: nil))
    end
      .to raise_error(ArgumentError)
  end
end
