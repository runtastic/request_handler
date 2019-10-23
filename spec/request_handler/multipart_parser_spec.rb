# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/multipart_parser'
describe RequestHandler::MultipartsParser do
  shared_examples_for 'returns expected result' do
    it do
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
      file = result[:file]
      expect(file[:filename]).to eq('rt.png')
      expect(file[:type]).to eq('image/png')
      expect(file[:name]).to eq('file')
      expect(file[:tempfile]).not_to be_nil
      expect(file[:head]).not_to be_nil
    end
  end

  shared_examples_for 'an invalid multipart request' do
    it do
      expect { handler.run }.to raise_error(RequestHandler::MultipartParamsError) do |raised_error|
        expect(raised_error.errors).to match_array([jsonapi_error])
      end
    end
  end

  let(:jsonapi_error) do
    {
      status: '400',
      code: 'INVALID_MULTIPART_REQUEST',
      detail: expected_jsonapi_error_detail
    }
  end
  let(:handler) do
    described_class.new(
      request:          request,
      multipart_config: config.multipart
    )
  end
  let(:request) do
    Rack::Request.new(env)
  end
  let(:env) do
    Rack::MockRequest.env_for(path, method: method, params: params)
  end
  let(:path) { '/' }
  let(:method) { 'POST' }
  let(:params) do
    {
      'user_id' => 'awesome_user_id',
      'id' =>      'fer342ref',
      'meta' => meta_file,
      'file' => other_file
    }
  end

  let(:other_file) do
    Rack::Multipart::UploadedFile.new('spec/fixtures/rt.png', 'image/png')
  end

  let(:video_file) do
    Rack::Multipart::UploadedFile.new('spec/fixtures/mocked_video.mp4', 'video/mp4')
  end

  let(:config) do
    Confstruct::Configuration.new do
      multipart do
        meta do
          required true
          type 'jsonapi'
          schema(Class.new(Dry::Validation::Contract) do
                   option :query_id
                   params do
                     required(:id).value(:string)
                     required(:type).value(eql?: 'post')
                     required(:user_id).filled(:string)
                     required(:name).filled(:string)
                     optional(:publish_on).filled(:time)

                     required(:category).schema do
                       required(:id).filled(:string)
                       required(:type).value(eql?: 'category')
                     end
                   end
                   rule(:id) do
                     key.failure('invalid id') unless values[:id] == query_id
                   end
                 end)
          options(->(_parser, request) { { query_id: request.params['id'] } })
        end

        file do
        end
      end
    end
  end

  let(:file_tempfile) { instance_double('Tempfile') }

  context 'jsonapi' do
    let(:meta_filename) { 'meta_jsonapi.json' }
    let(:meta_file) do
      Rack::Multipart::UploadedFile.new("spec/fixtures/#{meta_filename}", 'application/vnd.api+json')
    end

    it_behaves_like 'returns expected result'

    context 'invalid json payload' do
      let(:meta_filename) { 'invalid_meta.json' }
      let(:expected_jsonapi_error_detail) { 'sidecar resource is not valid JSON' }
      it_behaves_like 'an invalid multipart request'
    end

    context 'empty json payload' do
      let(:meta_filename) { 'empty_meta.json' }
      let(:expected_jsonapi_error_detail) { 'sidecar resource is not valid JSON' }
      it_behaves_like 'an invalid multipart request'
    end

    context 'config missing' do
      it do
        expect do
          described_class.new(request: request,
                              multipart_config: nil).run
        end
          .to raise_error(RequestHandler::MissingArgumentError)
      end
    end

    context 'sidecar resource not configured' do
      let(:params) do
        {
          'user_id' => 'awesome_user_id',
          'id' =>      'fer342ref',
          'meta' =>    meta_file,
          'file' =>    other_file,
          'video' =>   video_file
        }
      end

      it do
        result = handler.run
        expect(result[:video]).to eq(nil)
      end
    end

    context 'required sidecar resource not sent' do
      let(:params) do
        super().reject { |key| key == 'meta' }
      end

      let(:expected_jsonapi_error_detail) { 'missing required sidecar resource: meta' }
      it_behaves_like 'an invalid multipart request'
    end
  end

  context 'json' do
    let(:meta_filename) { 'meta_json.json' }
    let(:meta_file) do
      Rack::Multipart::UploadedFile.new("spec/fixtures/#{meta_filename}", 'application/json')
    end

    let(:config) do
      Confstruct::Configuration.new do
        multipart do
          meta do
            required true
            type 'json'
            schema(Class.new(Dry::Validation::Contract) do
                     option :query_id
                     params do
                       required(:id).value(:string)
                       required(:type).value(eql?: 'post')
                       required(:user_id).filled(:string)
                       required(:name).filled(:string)
                       optional(:publish_on).filled(:time)

                       required(:category).schema do
                         required(:id).filled(:string)
                         required(:type).value(eql?: 'category')
                       end
                     end
                     rule(:id) do
                       key.failure('invalid id') unless values[:id] == query_id
                     end
                   end)
            options(->(_parser, request) { { query_id: request.params['id'] } })
          end

          file do
          end
        end
      end
    end

    it_behaves_like 'returns expected result'

    context 'invalid json payload' do
      let(:meta_filename) { 'invalid_meta.json' }
      let(:expected_jsonapi_error_detail) { 'sidecar resource is not valid JSON' }
      it_behaves_like 'an invalid multipart request'
    end
  end
end
