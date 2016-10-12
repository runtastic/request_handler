# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/body_handler"
describe Dry::RequestHandler::BodyHandler do
  let(:handler) do
    described_class.new(schema: schema, request: build_mock_request(params: {}, headers: {}, body: raw_body))
  end
  shared_examples "flattens the body as expected" do
    it "returns the flattend body" do
      expect(handler).to receive(:validate_schema).with(wanted_result)
      handler.run
    end
  end

  let(:schema) { Dry::Validation.JSON {} }
  def build_mock_request(params:, headers:, body: "")
    # TODO: check if this double is close enough to a real Rack::Request
    instance_double("Rack::Request", params: params, env: headers, body: StringIO.new(body))
  end

  # flattens the body correctly with one relationships
  it_behaves_like "flattens the body as expected" do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "id": "fer342ref",
          "type": "post",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          },
          "relationships":{
            "category": {
              "data": {
                "id": "54",
                "type": "category"
              }
            }
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        "id"         => "fer342ref",
        "type"       => "post",
        "user_id"    => "awesome_user_id",
        "name"       => "About naming stuff and cache invalidation",
        "publish_on" => "2016-09-26T12:23:55Z",
        "category"   => {
          "id"   => "54",
          "type" => "category"
        }
      }
    end
  end

  # flattens the body correctly with multiple relationships
  it_behaves_like "flattens the body as expected" do
    let(:raw_body) do
      <<~JSON
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
              "data": {
                "id": "54",
                "type": "category"
              }
            },
            "comments": {
              "data": {
                "id": "1",
                "type": "comment"
              }
            }
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        "id"         => "fer342ref",
        "type"       => "post",
        "user_id"    => "awesome_user_id",
        "name"       => "About naming stuff and cache invalidation",
        "publish_on" => "2016-09-26T12:23:55Z",
        "category"   => {
          "id"   => "54",
          "type" => "category"
        },
        "comments"   => {
          "id"   => "1",
          "type" => "comment"
        }
      }
    end
  end

  # flattens the body correctly with an array in a relationship
  it_behaves_like "flattens the body as expected" do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "id": "fer342ref",
          "type": "post",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          },
          "relationships":{
            "category": {
              "data": [
                {
                  "id": "54",
                  "type": "category"
                },
                {
                  "id": "55",
                  "type": "category2"
                }
              ]
            }
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        "id"         => "fer342ref",
        "type"       => "post",
        "user_id"    => "awesome_user_id",
        "name"       => "About naming stuff and cache invalidation",
        "publish_on" => "2016-09-26T12:23:55Z",
        "category"   => [
          {
            "id"   => "54",
            "type" => "category"
          },
          {
            "id"   => "55",
            "type" => "category2"
          }
        ]
      }
    end
  end

  # flattens the body correctly without relationships
  it_behaves_like "flattens the body as expected" do
    let(:raw_body) do
      <<~JSON
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
    end
    let(:wanted_result) do
      {
        "id"         => "fer342ref",
        "type"       => "post",
        "user_id"    => "awesome_user_id",
        "name"       => "About naming stuff and cache invalidation",
        "publish_on" => "2016-09-26T12:23:55Z"
      }
    end
  end

  # flattens the body correctly without relationships and with different types of Inputs
  it_behaves_like "flattens the body as expected" do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "attributes": {
            "user_id": 2,
            "name": [1 ,2, 3],
            "published": false
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        "id"        => "fer342ref",
        "type"      => "post",
        "user_id"   => 2,
        "name"      => [1, 2, 3],
        "published" => false
      }
    end
  end

  # flattens the body correctly without attributes
  it_behaves_like "flattens the body as expected" do
    let(:raw_body) do
      <<~JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "relationships":{
            "category": {
              "data": {
                "id": "54",
                "type": "category"
              }
            }
          }
        }
      }
    JSON
    end
    let(:wanted_result) do
      {
        "id"       => "fer342ref",
        "type"     => "post",
        "category" => {
          "id"   => "54",
          "type" => "category"
        }
      }
    end
  end

  it "fails if the request is nil" do
    schema = Dry::Validation.JSON {}
    expect { described_class.new(schema: schema, request: nil) }.to raise_error(ArgumentError)
  end

  it "fails if the request body is nil" do
    schema = Dry::Validation.JSON {}
    expect do
      described_class.new(schema:  schema,
                          request: instance_double("Rack::Request", params: {}, env: {}, body: nil))
    end
      .to raise_error(ArgumentError)
  end
end
