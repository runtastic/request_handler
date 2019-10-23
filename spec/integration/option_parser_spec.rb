# frozen_string_literal: true

require 'spec_helper'
describe RequestHandler do
  shared_examples 'it validates options' do
    subject(:to_dto) { testclass.new(request: request).to_dto }
    let(:request) { build_mock_request(params: params, headers: {}, body: '') }
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
        context 'with a forbidden include query' do
          let(:params) { { include: 'foo,bar' } }
          it { expect { to_dto }.to raise_error(RequestHandler::OptionNotAllowedError) }
        end
        context 'with a space in the query parameter' do
          let(:params) { { include: 'user, groups' } }
          it { expect { to_dto }.to raise_error(RequestHandler::IncludeParamsError) }
        end
        context 'with no params' do
          let(:params) { nil }
          it { expect { to_dto }.to raise_error(RequestHandler::MissingArgumentError) }
        end
        context 'with params not being a hash' do
          let(:params) { 'Foo' }
          it { expect { to_dto }.to raise_error(RequestHandler::ExternalArgumentError) }
        end
        context 'with valid parameters and settings' do
          let(:params) { { include: 'user' } }
          it { expect(to_dto).to eq(OpenStruct.new(include: [:user])) }
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
        context 'with a forbidden sort query' do
          let(:params)  { { sort: 'foo,bar' } }
          it { expect { to_dto }.to raise_error(RequestHandler::OptionNotAllowedError) }
        end
        context 'with a space in the query parameter' do
          let(:params) { { sort: 'name, age' } }
          it { expect { to_dto }.to raise_error(RequestHandler::SortParamsError) }
        end
        context 'with no params' do
          let(:params) { nil }
          it { expect { to_dto }.to raise_error(RequestHandler::MissingArgumentError) }
        end
        context 'with params not being a hash' do
          let(:params) { 'Foo' }
          it { expect { to_dto }.to raise_error(RequestHandler::ExternalArgumentError) }
        end
        context 'with valid parameters and settings' do
          let(:params) { { sort: '-name' } }
          it { expect(to_dto).to eq(OpenStruct.new(sort: [RequestHandler::SortOption.new('name', :desc)])) }
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
    before do
      RequestHandler.configure do |rh_config|
        rh_config.validation_engine = RequestHandler::Validation::DefinitionEngine
      end
    end

    let(:enum_schema) do
      Definition.Enum(*enum_values)
    end

    include_context 'with definition validation engine' do
      it_behaves_like 'it validates options'
    end
  end
end
