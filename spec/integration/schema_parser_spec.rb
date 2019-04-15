# frozen_string_literal: true

require 'spec_helper'
describe RequestHandler do
  shared_examples 'it validates schemas' do
    context 'SchemaParser' do
      subject(:to_dto) { testclass.new(request: request).to_dto }
      context 'BodyParser' do
        let(:valid_jsonapi_body) do
          <<-JSON
          {
            "data": {
              "attributes": {
                "name": "About naming stuff and cache invalidation"
              }
            }
          }
          JSON
        end
        let(:invalid_jsonapi_body) do
          <<-JSON
          {
            "data": {
              "attributes": {
                "foo": "About naming stuff and cache invalidation"
              }
            }
          }
          JSON
        end
        let(:valid_json_body) do
          <<-JSON
          { "name": "About naming stuff and cache invalidation" }
          JSON
        end
        context 'valid schema' do
          context 'type jsonapi' do
            let(:testclass) do
              schema = required_name_schema
              Class.new(RequestHandler::Base) do
                options do
                  body do
                    type :jsonapi
                    schema(schema)
                  end
                end
                def to_dto
                  OpenStruct.new(
                    body: body_params
                  )
                end
              end
            end

            context 'when body does not conform to configured schema' do
              let(:request) { build_mock_request(params: {}, headers: {}, body: invalid_jsonapi_body) }
              let(:jsonapi_error) do
                {
                  status: '422',
                  code: 'INVALID_RESOURCE_SCHEMA',
                  title: 'Invalid resource',
                  detail: anything,
                  source: { pointer: '/data/attributes/name' }
                }
              end

              it 'raises a SchemaValidationError with invalid data' do
                expect { to_dto }.to raise_error(RequestHandler::SchemaValidationError) do |raised_error|
                  expect(raised_error.errors).to match_array([jsonapi_error])
                end
              end
            end

            context 'when body is missing' do
              let(:request) { instance_double('Rack::Request', params: {}, env: {}, body: nil) }
              it { expect { to_dto }.to raise_error(RequestHandler::MissingArgumentError) }
            end

            context "with a valid jsonapi document" do
              let(:request) do
                build_mock_request(params: {}, headers: {}, body: valid_jsonapi_body)
              end

              it do
                expect(to_dto).to eq(OpenStruct.new(body: { name: 'About naming stuff and cache invalidation' }))
              end
            end
          end

          context 'type not configured' do
            let(:testclass) do
              schema = required_name_schema
              Class.new(RequestHandler::Base) do
                options do
                  body do
                    schema(schema)
                  end
                end
                def to_dto
                  OpenStruct.new(
                    body: body_params
                  )
                end
              end
            end

            let(:request) do
              build_mock_request(params: {}, headers: {}, body: valid_jsonapi_body)
            end

            it 'defaults to jsonapi' do
              expect(to_dto).to eq(OpenStruct.new(body: { name: 'About naming stuff and cache invalidation' }))
            end
          end

          context 'type json' do
            let(:testclass) do
              schema = required_name_schema
              Class.new(RequestHandler::Base) do
                options do
                  body do
                    type :json
                    schema(schema)
                  end
                end
                def to_dto
                  OpenStruct.new(
                    body: body_params
                  )
                end
              end
            end
            context "with valid json data" do
              let(:request) do
                build_mock_request(params: {}, headers: {}, body: valid_json_body)
              end
              
              it { is_expected.to eq(OpenStruct.new(body: { name: 'About naming stuff and cache invalidation' })) }
            end
          end
        end
        context 'invalid schema' do
          let(:testclass) do
            Class.new(RequestHandler::Base) do
              options do
                body do
                  type :jsonapi
                  schema 'Foo'
                end
              end
              def to_dto
                OpenStruct.new(
                  body:  body_params
                )
              end
            end
          end
          let(:request) { build_mock_request(params: {}, headers: {}, body: valid_jsonapi_body) }
          it 'raises a InternalArgumentError' do
            expect { to_dto }.to raise_error(RequestHandler::InternalArgumentError)
          end
        end
      end

      context 'FilterParser' do
        let(:valid_params) do
          {
            'filter' => {
              'name' => 'foo'
            }
          }
        end
        let(:invalid_params) do
          {
            'filter' => {
              'bar' => 'foo'
            }
          }
        end
        context 'valid schema' do
          let(:testclass) do
            schema = required_name_schema
            Class.new(RequestHandler::Base) do
              options do
                filter do
                  schema(schema)
                  defaults(foo: 'bar')
                end
              end
              def to_dto
                OpenStruct.new(
                  filter:  filter_params
                )
              end
            end
          end

          context "with invalid data" do
            let(:request) do
              build_mock_request(params: invalid_params, headers: {}, body: '')
            end

            it 'raises a FilterParamsError' do
              expect { to_dto }.to raise_error(RequestHandler::FilterParamsError) do |raised_error|
                expect(raised_error.errors).to match_array([{
                                                             status: '400',
                                                             code: 'INVALID_QUERY_PARAMETER',
                                                             detail: anything,
                                                             source: { param: 'filter[name]' }
                                                           }])
              end
            end

            context "when rendering json api errors is disabled" do
              before { RequestHandler.configuration.raise_jsonapi_errors = false }

              it "raises a FilterParamsError without details" do
                expect { to_dto }.to raise_error(RequestHandler::FilterParamsError) do |raised_error|
                  expect(raised_error.errors).to match_array([])
                end
              end
            end
          end

          context "when params are missing" do
            let(:request) { build_mock_request(params: nil, headers: {}, body: '') }
            it { expect { to_dto }.to raise_error(RequestHandler::MissingArgumentError) }
          end

          context "with valid params" do
            let(:request) { build_mock_request(params: valid_params, headers: {}, body: '') }
            it { expect(to_dto).to eq(OpenStruct.new(filter: { name: 'foo', foo: 'bar' })) }
          end
        end
        context 'invalid schema' do
          let(:testclass) do
            Class.new(RequestHandler::Base) do
              options do
                filter do
                  schema 'Foo'
                end
              end
              def to_dto
                OpenStruct.new(
                  filter: filter_params
                )
              end
            end
          end
          let(:request) { build_mock_request(params: valid_params, headers: {}, body: '') }
          it { expect { to_dto }.to raise_error(RequestHandler::InternalArgumentError) }
        end
      end

      context 'QueryParser' do
        let(:valid_params) do
          {
            'name' => 'foo',
            'filter' => {
              'post' => 'bar'
            }
          }
        end
        let(:invalid_params) do
          {
            'name' => nil,
            'filter' => {
              'post' => 'bar'
            }
          }
        end
        context 'valid schema' do
          let(:testclass) do
            schema = required_name_schema
            Class.new(RequestHandler::Base) do
              options do
                query do
                  schema(schema)
                end
              end
              def to_dto
                OpenStruct.new(
                  query: query_params
                )
              end
            end
          end
          context "with invalid data" do
            let(:request) { build_mock_request(params: invalid_params, headers: {}, body: '') }
            it { expect { to_dto }.to raise_error(RequestHandler::ExternalArgumentError) }
          end

          context "with missing data" do
            let(:request) { build_mock_request(params: nil, headers: {}, body: '') }
            it { expect { to_dto }.to raise_error(RequestHandler::MissingArgumentError) }
          end

          context "with valid data" do
            let(:request) { build_mock_request(params: valid_params, headers: {}, body: '') }
            it { expect(to_dto).to eq(OpenStruct.new(query: { name: 'foo' })) }
          end
        end
        context 'invalid schema' do
          let(:testclass) do
            Class.new(RequestHandler::Base) do
              options do
                query do
                  schema 'Foo'
                end
              end
              def to_dto
                OpenStruct.new(
                  query: query_params
                )
              end
            end
          end
          context "with valid data" do
            let(:request) { build_mock_request(params: valid_params, headers: {}, body: '') }
            it { expect { to_dto }.to raise_error(RequestHandler::InternalArgumentError) }
          end
        end
      end
    end
  end

  context 'with dry engine' do
    let(:required_name_schema) do
      Dry::Validation.JSON do
        required(:name).filled(:str?)
      end
    end

    include_context 'with dry validation engine' do
      it_behaves_like 'it validates schemas'
    end
  end

  context 'with definition engine' do
    let(:required_name_schema) do
      Definition.Keys do
        option :ignore_extra_keys

        required :name, Definition.NonEmptyString
      end
    end

    include_context 'with definition validation engine' do
      it_behaves_like 'it validates schemas'
    end
  end
end
