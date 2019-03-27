# frozen_string_literal: true

require 'spec_helper'
describe RequestHandler do
  shared_examples 'it validates options' do
    context 'Option Parser' do
      context 'IncludeOptionParser' do
        let(:enum_values) { %w[user groups] }
        let(:testclass) do
          schema = enum_schema
          Class.new(RequestHandler::Base) do
            options do
              include_options do
                allowed schema
                defaults %i[foo bar]
              end
            end
            def to_dto
              OpenStruct.new(
                include: include_params
              )
            end
          end
        end
        it 'raises an OptionNotAllowedError if there is a include query that is not allowed' do
          request = build_mock_request(params: { 'include' => 'foo,bar' }, headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(RequestHandler::OptionNotAllowedError)
        end
        it 'raises an ExternalArgumentError if the query parameter contains as space' do
          request = build_mock_request(params: { 'include' => 'user, groups' }, headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(RequestHandler::IncludeParamsError)
        end
        it 'raises a InternalArgumentError if params is set to nil' do
          request = build_mock_request(params: nil, headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(RequestHandler::MissingArgumentError)
        end
        it 'raises a ExternalArgumentError if params is no Hash' do
          request = build_mock_request(params: 'Foo', headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(RequestHandler::ExternalArgumentError)
        end
        it 'works for valid paramaters and settings' do
          request = build_mock_request(params: { 'include' => 'user' }, headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect(testhandler.to_dto).to eq(OpenStruct.new(include: [:user]))
        end
      end
      context 'SortOptionParser' do
        let(:enum_values) { %w[name age] }
        let(:testclass) do
          schema = enum_schema
          Class.new(RequestHandler::Base) do
            options do
              sort_options do
                allowed schema
              end
            end
            def to_dto
              OpenStruct.new(
                sort: sort_params
              )
            end
          end
        end
        it 'raises an OptionNotAllowedError if there is a sort query that is not allowed' do
          request = build_mock_request(params: { 'sort' => 'foo,bar' }, headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(RequestHandler::OptionNotAllowedError)
        end
        it 'raises an ExternalArgumentError if the query parameter contains as space' do
          request = build_mock_request(params: { 'sort' => 'name, age' }, headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(RequestHandler::SortParamsError)
        end
        it 'raises an MissingArgumentError if params is set to nil' do
          request = build_mock_request(params: nil, headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(RequestHandler::MissingArgumentError)
        end
        it 'raises an ExternalArgumentError if params is not a Hash' do
          request = build_mock_request(params: 'Foo', headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect { testhandler.to_dto }.to raise_error(RequestHandler::ExternalArgumentError)
        end
        it 'works for valid paramaters and settings' do
          request = build_mock_request(params: { 'sort' => '-name' }, headers: {}, body: '')
          testhandler = testclass.new(request: request)
          expect(testhandler.to_dto)
            .to eq(OpenStruct.new(sort: [RequestHandler::SortOption.new('name', :desc)]))
        end
      end
    end
  end

  context 'with dry engine' do
    let(:enum_schema) do
      Dry::Types['strict.string'].enum(*enum_values)
    end

    include_context 'with dry validation engine' do
      it_behaves_like 'it validates options'
    end
  end

  context 'with definition engine' do
    let(:enum_schema) do
      Definition.Enum(*enum_values)
    end

    include_context 'with definition validation engine' do
      it_behaves_like 'it validates options'
    end
  end
end
