# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/body_parser'
require 'request_handler/json_api_document_parser'
require 'request_handler/json_parser'

describe RequestHandler::BodyParser do
  let(:handler) do
    described_class.new(
      schema:           schema,
      request:          build_mock_request(params: {}, headers: headers, body: raw_body)
    )
  end

  let(:schema) { Dry::Validation.JSON {} }

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

  context 'jsonapi' do
    let(:headers) { { 'Content-Type' => 'application/vnd.api+json' } }

    it 'constructs and runs jsonApiDocumentParser correctly' do
      parser_double = instance_double(RequestHandler::JsonApiDocumentParser)
      expect(RequestHandler::JsonApiDocumentParser)
        .to receive(:new)
        .with(document: MultiJson.load(raw_body), schema: schema, schema_options: {})
        .and_return(parser_double)

      result_double = instance_double(Hash)
      expect(parser_double).to receive(:run).and_return(result_double)
      expect(handler.run).to eq(result_double)
    end

    it 'fails if the request body is nil' do
      schema = Dry::Validation.JSON {}
      expect do
        described_class.new(schema:  schema,
                            request: instance_double('Rack::Request', params: {}, env: headers, body: nil))
      end
        .to raise_error(RequestHandler::MissingArgumentError)
    end

    it 'fails if the request body does not contain a data hash' do
      schema = Dry::Validation.JSON {}
      expect do
        described_class.new(
          schema:  schema,
          request: instance_double('Rack::Request',
                                   params: {},
                                   env: headers,
                                   body: StringIO.new('{"include": [{"type": "foo", "id": "bar"}]}'))
        ).run
      end
        .to raise_error(RequestHandler::BodyParamsError)
    end
  end

  context 'json' do
    let(:headers) { { 'Content-Type' => 'application/json' } }

    it 'constructs and runs JsonParser correctly' do
      parser_double = instance_double(RequestHandler::JsonParser)
      expect(RequestHandler::JsonParser)
        .to receive(:new)
        .with(document: MultiJson.load(raw_body), schema: schema, schema_options: {})
        .and_return(parser_double)

      result_double = instance_double(Hash)
      expect(parser_double).to receive(:run).and_return(result_double)
      expect(handler.run).to eq(result_double)
    end

    it 'fails if the request body is nil' do
      schema = Dry::Validation.JSON {}
      expect do
        described_class.new(schema:  schema,
                            request: instance_double('Rack::Request', params: {}, env: headers, body: nil))
      end
        .to raise_error(RequestHandler::MissingArgumentError)
    end

    it "doesn't fail if the request body does not contain a data hash" do
      schema = Dry::Validation.JSON {}
      expect do
        described_class.new(
          schema:  schema,
          request: instance_double('Rack::Request',
                                   params: {},
                                   env: headers,
                                   body: StringIO.new('{"include": [{"type": "foo", "id": "bar"}]}'))
        ).run
      end
        .not_to raise_error
    end
  end
end
