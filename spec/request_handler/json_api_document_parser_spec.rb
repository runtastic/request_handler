# frozen_string_literal: true

require "spec_helper"
require "request_handler/json_api_document_parser"
describe RequestHandler::JsonApiDocumentParser do
  let(:handler) do
    described_class.new(
      schema:   schema,
      document: document
    )
  end
  let(:schema) { Dry::Schema.JSON {} }
  let(:document) do
    raw_body.empty? ? {} : MultiJson.load(raw_body)
  end

  shared_examples "flattens the body as expected" do
    it "returns the flattened body" do
      expect(handler).to receive(:validate_schema).with(wanted_result)
      handler.run
    end
  end

  context "one relationships" do
    let(:raw_body) do
      <<-JSON
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

    it_behaves_like "flattens the body as expected"
  end

  context "with attributes, relationships, links and meta" do
    let(:raw_body) do
      <<-JSON
      {
        "data": {
          "id": "fer342ref",
          "type": "post",
          "attributes": {
            "user_id": "awesome_user_id"
          },
          "relationships":{
            "category": {
              "data": {
                "id": "54",
                "type": "category"
              }
            }
          },
          "links": {
            "self": "http://example.com/1"
          },
          "meta": {
            "foo": "bar"
          }
        }
      }
      JSON
    end
    let(:wanted_result) do
      {
        "id"       => "fer342ref",
        "type"     => "post",
        "user_id"  => "awesome_user_id",
        "category" => {
          "id"   => "54",
          "type" => "category"
        },
        "links"    => {
          "self" => "http://example.com/1"
        },
        "meta"     => {
          "foo" => "bar"
        }
      }
    end

    it_behaves_like "flattens the body as expected"
  end

  context "multiple relationships" do
    let(:raw_body) do
      <<-JSON
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

    it_behaves_like "flattens the body as expected"
  end

  context "array in a relationship" do
    let(:raw_body) do
      <<-JSON
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

    it_behaves_like "flattens the body as expected"
  end

  context "without relationships" do
    let(:raw_body) do
      <<-JSON
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

    it_behaves_like "flattens the body as expected"
  end

  context "different types of Inputs" do
    let(:raw_body) do
      <<-JSON
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

    it_behaves_like "flattens the body as expected"
  end

  context "without attributes" do
    let(:raw_body) do
      <<-JSON
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

    it_behaves_like "flattens the body as expected"
  end

  context "when relationship data is empty" do
    let(:raw_body) do
      <<-JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "relationships":{
            "category": {
              "data": null
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
        "category" => nil
      }
    end

    it_behaves_like "flattens the body as expected"
  end

  context "when body is empty" do
    let(:document) { nil }

    it "raises a MissingArgumentError" do
      expect { handler }.to raise_error(RequestHandler::MissingArgumentError)
    end
  end

  context "when body does not contain data hash" do
    let(:document) { JSON.parse('{"include": [{"type": "foo", "id": "bar"}]}') }

    it "raises an ExternalArgumentError" do
      expect { handler.run }.to raise_error do |error|
        expect(error).to be_a(RequestHandler::ExternalArgumentError)
        expected_error = {
          code:   "INVALID_JSON_API",
          status: "400",
          title:  "Body is not a valid JSON API payload",
          detail: "Member 'data' is missing",
          source: { pointer: "/" }
        }
        expect(error.errors).to contain_exactly(expected_error)
      end
    end
  end

  context "when 'data' contains non-JSONAPI members" do
    let(:raw_body) do
      <<-JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "attributes": {
            "foo": "bar"
          },
          "non_jsonapi_member": "baz"
        }
      }
      JSON
    end

    it "raises an ExternalArgumentError" do
      expect { handler.run }.to raise_error do |error|
        expect(error).to be_a(RequestHandler::ExternalArgumentError)
        expected_error = {
          code:   "INVALID_JSON_API",
          status: "400",
          title:  "Body is not a valid JSON API payload",
          detail: "Member 'data' contains invalid member!",
          source: { pointer: "/data/non_jsonapi_member" }
        }
        expect(error.errors).to contain_exactly(expected_error)
      end
    end
  end
end
