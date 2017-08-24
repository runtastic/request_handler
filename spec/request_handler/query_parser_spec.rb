# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/query_parser'
describe RequestHandler::QueryParser do
  shared_examples 'proccesses query params correctly' do
    it 'outputs the query params in a flat way' do
      handler = described_class.new(schema: schema, params: params)
      expect(handler.run).to eq(output)
    end
  end

  context 'one query param' do
    let(:params) do
      { 'name' => 'foo' }
    end
    let(:schema) do
      Dry::Validation.Schema do
        required('name').filled
      end
    end
    let(:output)  do
      { 'name' => 'foo' }
    end
    it_behaves_like 'proccesses query params correctly'
  end

  context 'one query param and multiple reserved params' do
    let(:params) do
      {
        'name' => 'foo',
        'page' => {
          'number' => '1',
          'size' => '5'
        },
        'sort' => 'id,-date',
        'fields' => {
          'posts' => 'awesome'
        },
        'include' => 'user,email',
        'filter' => {
          'name' => 'bar'
        }
      }
    end
    let(:schema) do
      Dry::Validation.Schema do
        required('name').filled
      end end
    let(:output) do
      {
        'name' => 'foo'
      }
    end
    it_behaves_like 'proccesses query params correctly'
  end

  context 'no query params set' do
    let(:params) { {} }
    let(:schema) { Dry::Validation.Schema {} }
    let(:output) { {} }
    it_behaves_like 'proccesses query params correctly'
  end

  context 'optional query param' do
    let(:schema) do
      Dry::Validation.Schema do
        optional('name').filled
      end
    end
    context 'param given' do
      let(:params) do
        { 'name' => 'foo' }
      end
      let(:output) do
        {
          'name' => 'foo'
        }
      end
      it_behaves_like 'proccesses query params correctly'
    end

    context 'param not given' do
      let(:params) { {} }
      let(:output) { {} }
      it_behaves_like 'proccesses query params correctly'
    end
  end
end
