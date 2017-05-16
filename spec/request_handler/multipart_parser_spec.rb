# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/multipart_parser'
describe RequestHandler::MultipartsParser do
  let(:handler) do
    described_class.new(
      request:           build_mock_request(params: params, headers: {}),
      multipart_config: config.multipart
    )
  end
  let(:config) do
    Confstruct::Configuration.new do
      multipart do
        meta do
          schema(Dry::Validation.JSON do
            configure do
              option :query_id
            end
            required(:id).value(eql?: query_id)
            required(:type).value(eql?: 'post')
            required(:user_id).filled(:str?)
            required(:name).filled(:str?)
            optional(:publish_on).filled(:time?)

            required(:category).schema do
              required(:id).filled(:str?)
              required(:type).value(eql?: 'category')
            end
          end)
          options(->(_parser, request) { { query_id: request.params['id'] } })
        end

        file do
        end
      end
    end
  end

  let(:raw_meta) do
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
            }
          }
        }
      }
    JSON
  end

  let(:params) do
    {
      'user_id' => 'awesome_user_id',
      'id'      => 'fer342ref',
      'meta'    => { filename: 'meta.json', tempfile: instance_double('Tempfile', read: raw_meta) },
      'file'    => { filename: 'rt.jpg', tempfile: file_tempfile }
    }
  end
  let(:file_tempfile) { instance_double('Tempfile') }

  it 'returns expected result' do
    result = handler.run
    expect(result[:meta]).to eq(id:         'fer342ref',
                                type:       'post',
                                user_id:    'awesome_user_id',
                                name:       'About naming stuff and cache invalidation',
                                publish_on: Time.iso8601('2016-09-26T12:23:55Z'),
                                category:   {
                                  id:   '54',
                                  type: 'category'
                                })
    expect(result[:file]).to eq(filename: 'rt.jpg', tempfile: file_tempfile)
  end

  it 'fails if params missing' do
    expect do
      described_class.new(request: instance_double('Rack::Request', params: nil, env: {}, body: nil),
                          multipart_config: config.multipart)
    end
      .to raise_error(RequestHandler::MissingArgumentError)
  end

  it 'fails if config missing' do
    expect do
      described_class.new(request: instance_double('Rack::Request', params: params, env: {}, body: nil),
                          multipart_config: nil)
    end
      .to raise_error(RequestHandler::MissingArgumentError)
  end

  it 'fails if configured param missing' do
    expect do
      described_class.new(request: instance_double('Rack::Request', params: params.delete('meta'), env: {}, body: nil),
                          multipart_config: config.multipart).run
    end
      .to raise_error(RequestHandler::ExternalArgumentError)
  end

  it 'fails if file for validated multipart is missing' do
    params['meta'][:tempfile] = nil
    expect do
      described_class.new(request: instance_double('Rack::Request', params: params, env: {}, body: nil),
                          multipart_config: config.multipart).run
    end
      .to raise_error(RequestHandler::ExternalArgumentError)
  end

  context 'invalid json payload' do
    let(:raw_meta) do
      <<-JSON
        "data": {{
      JSON
    end

    it 'fails' do
      expect do
        described_class.new(request: instance_double('Rack::Request', params: params, env: {}, body: nil),
                            multipart_config: config.multipart).run
      end
          .to raise_error(RequestHandler::ExternalArgumentError)
    end
  end

  context 'empty json payload' do
    let(:raw_meta) { '' }

    it 'fails' do
      expect do
        described_class.new(request: instance_double('Rack::Request', params: params, env: {}, body: nil),
                            multipart_config: config.multipart).run
      end
          .to raise_error(RequestHandler::ExternalArgumentError)
    end
  end
end
