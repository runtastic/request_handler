# frozen_string_literal: true
require 'spec_helper'
require 'request_handler/body_parser'
require 'request_handler/json_api_data_parser'
describe RequestHandler::BodyParser do
  let(:handler) do
    described_class.new(
      schema:           schema,
      request:          build_mock_request(params: {}, headers: {}, body: raw_body),
      included_schemas: included_schemas
    )
  end
  let(:schema) { Dry::Validation.JSON {} }

  let(:included_schemas) do
    {
      people:   schema,
      comments: schema
    }
  end
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

  it 'constructs and runs jsonApiParser correctly' do
    parser_double = instance_double(RequestHandler::JsonApiDataParser)
    expect(RequestHandler::JsonApiDataParser)
      .to receive(:new)
      .with(data: MultiJson.load(raw_body), schema: schema, schema_options: {}, included_schemas: included_schemas)
      .and_return(parser_double)

    result_double = instance_double(Hash)
    expect(parser_double).to receive(:run).and_return(result_double)
    expect(handler.run).to eq(result_double)
  end

  it 'fails if the request body is nil' do
    schema = Dry::Validation.JSON {}
    expect do
      described_class.new(schema:  schema,
                          request: instance_double('Rack::Request', params: {}, env: {}, body: nil))
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
                                 env: {},
                                 body: StringIO.new('{"include": [{"type": "foo", "id": "bar"}]}'))
      ).run
    end
      .to raise_error(RequestHandler::ExternalArgumentError)
  end
end
