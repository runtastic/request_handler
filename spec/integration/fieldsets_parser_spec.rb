# frozen_string_literal: true

require 'spec_helper'
describe RequestHandler do
  shared_examples 'it validates fieldsets' do
    let(:enum_values) { %w[foo bar] }
    subject(:to_dto) { testclass.new(request: request).to_dto }
    context 'with required fieldset' do
      let(:testclass) do
        schema = enum_schema
        Class.new(RequestHandler::Base) do
          options do
            fieldsets do
              allowed do
                resource :posts, schema
              end
              required [:posts]
            end
          end
          def to_dto
            OpenStruct.new(
              fieldsets: fieldsets_params
            )
          end
        end
      end

      context 'with valid request' do
        let(:request) { build_mock_request(params: { 'fields' => { 'posts' => 'foo,bar' } }, headers: nil, body: '') }
        it { expect(to_dto).to eq(OpenStruct.new(fieldsets: { posts: %i[foo bar] })) }
      end

      context 'with a request containing a not allowed option' do
        let(:request) { build_mock_request(params: { 'fields' => { 'photos' => 'bar' } }, headers: nil, body: '') }
        let(:expected_message) do
          /INVALID_QUERY_PARAMETER:.*param.*fields\[photos\].*fieldset for 'photos' not allowed/
        end
        it do
          expect { to_dto }.to raise_error(RequestHandler::OptionNotAllowedError) do |raised_error|
            expect(raised_error.message).to match(expected_message)
            jsonapi_error = { code: 'INVALID_QUERY_PARAMETER',
                              status: '400',
                              detail: "fieldset for 'photos' not allowed",
                              source: { parameter: 'fields[photos]' } }
            expect(raised_error.errors).to match_array([jsonapi_error])
          end
        end

        context 'when raising json api error data is disabled' do
          before { RequestHandler.configuration.raise_jsonapi_errors = false }
          it do
            expect { to_dto }.to raise_error(RequestHandler::OptionNotAllowedError) do |raised_error|
              expect(raised_error.errors).to match_array([])
              expect(raised_error.message).to match(expected_message)
            end
          end
        end
      end

      context 'with a value not allowed for a type' do
        let(:request) { build_mock_request(params: { 'fields' => { 'posts' => 'no' } }, headers: nil, body: '') }
        it { expect { to_dto }.to raise_error(RequestHandler::FieldsetsParamsError) }
      end

      context 'with a value that is not allowed for a type' do
        before { testclass.config.config.fieldsets.allowed.posts = %w[foo bar] }
        let(:request) { build_mock_request(params: { 'fields' => { 'posts' => 'foo' } }, headers: nil, body: '') }
        it { expect { to_dto }.to raise_error(RequestHandler::InternalArgumentError) }
      end
    end

    context 'with optional fieldset' do
      let(:testclass) do
        Class.new(RequestHandler::Base) do
          options do
            fieldsets do
              allowed do
                resource :posts, true
              end
            end
          end

          def to_dto
            OpenStruct.new(fieldsets: fieldsets_params)
          end
        end
      end

      context 'with fields an empty hash' do
        let(:request) { build_mock_request(params: { 'fields' => {} }, headers: nil, body: '') }
        it { expect(to_dto).to eq(OpenStruct.new(fieldsets: {})) }
      end

      context 'with fields filled with allowed params' do
        let(:request) { build_mock_request(params: { 'fields' => { 'posts' => 'foo,bar' } }, headers: nil, body: '') }
        it { expect(to_dto).to eq(OpenStruct.new(fieldsets: { posts: %i[foo bar] })) }
      end

      context 'without fields' do
        let(:request) { build_mock_request(params: { 'filter' => {} }, headers: nil, body: '') }
        it { expect(to_dto).to eq(OpenStruct.new(fieldsets: {})) }
      end

      context 'with fields for a forbidden type' do
        let(:request) { build_mock_request(params: { 'fields' => { 'photos' => 'bar' } }, headers: nil, body: '') }
        it { expect { to_dto }.to raise_error(RequestHandler::OptionNotAllowedError) }
      end
    end
  end

  context 'with dry engine' do
    let(:enum_schema) do
      Dry::Types['strict.string'].enum(*enum_values)
    end

    include_context 'with dry validation engine' do
      it_behaves_like 'it validates fieldsets'
    end
  end

  context 'with definition engine' do
    before do
      RequestHandler.configure do |rh_config|
        rh_config.validation_engine = RequestHandler::Validation::DefinitionEngine
      end
    end
    let(:enum_schema) do
      Definition.Enum(*enum_values)
    end

    include_context 'with definition validation engine' do
      it_behaves_like 'it validates fieldsets'
    end
  end
end
