# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/filter_parser'
describe RequestHandler::FilterParser do
  subject(:instance) do
    described_class.new(schema: schema, params: params, additional_url_filter: additional_url_filter)
  end
  shared_examples 'proccesses the filters correctly' do
    it 'outputs the filters in a flat way' do
      expect(instance.run).to eq(output)
    end
  end

  let(:additional_url_filter) { [] }

  context 'one normal filter' do
    let(:params) do
      { 'filter' => { 'name' => 'foo' } }
    end
    let(:schema) do
      Dry::Schema.Params do
        required(:name).filled
      end
    end
    let(:output) do
      { name: 'foo' }
    end
    it_behaves_like 'proccesses the filters correctly'
  end

  context 'one additional_url_filter' do
    let(:params) do
      {
        'name' => 'foo'
      }
    end
    let(:additional_url_filter) { ['name'] }
    let(:schema) do
      Dry::Schema.Params do
        required(:name).filled
      end
    end
    let(:output) do
      {
        name: 'foo'
      }
    end
    it_behaves_like 'proccesses the filters correctly'
  end

  context 'one additional_url_filter and one normal filter' do
    let(:params) do
      {
        'name'   => 'foo',
        'filter' => {
          'test' => 'bar'
        }
      }
    end
    let(:additional_url_filter) { ['name'] }
    let(:schema) do
      Dry::Schema.Params do
        required(:name).filled
        required(:test).filled
      end end
    let(:output) do
      {
        name: 'foo',
        test: 'bar'
      }
    end
    it_behaves_like 'proccesses the filters correctly'
  end

  context 'no filter set' do
    let(:params) do
      {
        'filter' => {
        }
      }
    end
    let(:schema) { Dry::Schema.Params {} }
    let(:output) { {} }
    it_behaves_like 'proccesses the filters correctly'
  end

  context 'without the filter hash' do
    let(:params) do
      {
      }
    end
    let(:schema) { Dry::Schema.Params {} }
    let(:output) { {} }
    it_behaves_like 'proccesses the filters correctly'
  end

  context 'when a filter was set twice' do
    let(:params) do
      {
        'name'   => 'foo',
        'filter' => {
          'name' => 'bar'
        }
      }
    end
    let(:schema) { Dry::Schema.Params { required(:name).filled } }
    let(:additional_url_filter) { [:name] }
    it { expect { instance }.to raise_error(RequestHandler::InternalArgumentError) }
  end

  context 'when filter param is a string' do
    let(:params) { { 'filter' => 'nope' } }
    let(:schema) { Dry::Schema.Params { required(:name).filled } }
    it do
      expect { instance }.to raise_error(RequestHandler::FilterParamsError) do |raised_error|
        jsonapi_error = {
          status: '400',
          code: 'INVALID_QUERY_PARAMETER',
          source: { param: 'filter' },
          detail: 'Filter parameter must conform to JSON API recommendation',
          links: { about: anything }
        }
        expect(raised_error.errors).to match_array([jsonapi_error])
      end
    end
  end
end
