# frozen_string_literal: true

require 'spec_helper'
describe RequestHandler do
  shared_examples 'it validates fieldsets' do
    let(:enum_values) { %w[foo bar] }
    context 'with required fieldset' do
      let(:testclass) do
        schema = enum_schema
        Class.new(RequestHandler::Base) do
          options do
            fieldsets do
              allowed do
                posts(schema)
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

      it 'works for a valid request' do
        request = build_mock_request(params: { 'fields' => { 'posts' => 'foo,bar' } }, headers: nil, body: '')
        testhandler = testclass.new(request: request)
        expect(testhandler.to_dto).to eq(OpenStruct.new(fieldsets: { posts: %i[foo bar] }))
      end

      it 'raises an OptionNotAllowedError if the client sends a type not allowed on the server' do
        request = build_mock_request(params: { 'fields' => { 'photos' => 'bar' } }, headers: nil, body: '')
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(RequestHandler::OptionNotAllowedError)
      end

      it 'raises an ExternalArgumentError if the client sends a value that is not allowed for a type' do
        request = build_mock_request(params: { 'fields' => { 'posts' => 'no' } }, headers: nil, body: '')
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(RequestHandler::FieldsetsParamsError)
      end
      it 'raises an InternalArgumentError if the client sends a value that is not allowed for a type' do
        testclass.config.fieldsets.allowed.posts = %w[foo bar]
        request = build_mock_request(params: { 'fields' => { 'posts' => 'foo' } }, headers: nil, body: '')
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(RequestHandler::InternalArgumentError)
      end
    end

    context 'with optional fieldset' do
      let(:testclass) do
        Class.new(RequestHandler::Base) do
          options do
            fieldsets do
              allowed do
                posts true
              end
            end
          end

          def to_dto
            OpenStruct.new(
              fieldsets: fieldsets_params
            )
          end
        end
      end

      it 'works fields is an empty hash' do
        request = build_mock_request(params: { 'fields' => {} }, headers: nil, body: '')
        testhandler = testclass.new(request: request)
        expect(testhandler.to_dto).to eq(OpenStruct.new(fieldsets: {}))
      end

      it 'works when fields is filled with allowed params' do
        request = build_mock_request(params: { 'fields' => { 'posts' => 'foo,bar' } }, headers: nil, body: '')
        testhandler = testclass.new(request: request)
        expect(testhandler.to_dto).to eq(OpenStruct.new(fieldsets: { posts: %i[foo bar] }))
      end

      it 'works when fields is not passed' do
        request = build_mock_request(params: { 'filter' => {} }, headers: nil, body: '')
        testhandler = testclass.new(request: request)
        expect(testhandler.to_dto).to eq(OpenStruct.new(fieldsets: {}))
      end

      it 'raises an OptionNotAllowedError if the client sends a type not allowed on the server' do
        request = build_mock_request(params: { 'fields' => { 'photos' => 'bar' } }, headers: nil, body: '')
        testhandler = testclass.new(request: request)
        expect { testhandler.to_dto }.to raise_error(RequestHandler::OptionNotAllowedError)
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
    let(:enum_schema) do
      Definition.Enum(*enum_values)
    end

    include_context 'with definition validation engine' do
      it_behaves_like 'it validates fieldsets'
    end
  end
end
