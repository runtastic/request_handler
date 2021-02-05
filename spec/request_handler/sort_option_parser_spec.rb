# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/sort_option_parser'
describe RequestHandler::SortOptionParser do
  let(:handler) do
    options_type = Dry::Types['strict.string'].enum('id', 'date', 'posts__created_at')
    described_class.new(params: params,
                        allowed_options_type: options_type)
  end
  shared_examples 'processes valid sort options correctly' do
    it 'returns the right sort options' do
      expect(handler.run).to eq(output)
    end
  end
  let(:jsonapi_error) { anything }
  shared_examples 'processes invalid sort options correctly' do
    it 'raises an error with invalid sort options' do
      expect { handler.run }.to raise_error(error) do |raised_error|
        expect(raised_error.errors).to match_array([jsonapi_error])
      end
    end
  end

  context 'one ascending sort order for an allowed option' do
    let(:params) { { 'sort' => 'id' } }
    let(:output) { [RequestHandler::SortOption.new('id', :asc)] }
    it_behaves_like 'processes valid sort options correctly'
  end

  context 'one ascending sort order for an allowed option' do
    let(:params) { { 'sort' => '-id' } }
    let(:output) { [RequestHandler::SortOption.new('id', :desc)] }
    it_behaves_like 'processes valid sort options correctly'
  end

  context 'one ascending and one descending order for allowed options' do
    let(:params) { { 'sort' => 'id,-date' } }
    let(:output) do
      [RequestHandler::SortOption.new('id', :asc),
       RequestHandler::SortOption.new('date', :desc)]
    end
    it_behaves_like 'processes valid sort options correctly'
  end

  context 'nested attributes as sort options are correctly transformed' do
    let(:params) { { 'sort' => 'posts.created_at' } }
    let(:output) do
      [RequestHandler::SortOption.new('posts__created_at', :asc)]
    end
    it_behaves_like 'processes valid sort options correctly'
  end

  let(:jsonapi_error) do
    {
      code: 'INVALID_QUERY_PARAMETER',
      status: '400',
      detail: expected_detail,
      source: { parameter: 'sort' }
    }
  end

  context 'no sort options are specified' do
    let(:params) { { 'sort' => '' } }
    let(:output) { [] }
    let(:error) { RequestHandler::SortParamsError }
    let(:expected_detail) { 'must not be empty' }
    it_behaves_like 'processes invalid sort options correctly'
  end

  context 'sort param is not set' do
    let(:params) { {} }
    let(:output) { [] }
    it_behaves_like 'processes valid sort options correctly'
  end

  context 'sort key is not unique and the order is different in the duplicate' do
    let(:params) { { 'sort' => 'id,-id' } }
    let(:error) { RequestHandler::SortParamsError }
    let(:expected_detail) { 'sort options must be unique' }
    it_behaves_like 'processes invalid sort options correctly'
  end

  context 'sort key is not unique and the order is identical in the duplicate' do
    let(:params) { { 'sort' => 'id,id' } }
    let(:error) { RequestHandler::SortParamsError }
    let(:expected_detail) { 'sort options must be unique' }
    it_behaves_like 'processes invalid sort options correctly'
  end

  context 'one of the sort keys contains spaces' do
    let(:params) { { 'sort' => 'id, foo' } }
    let(:error) { RequestHandler::SortParamsError }
    let(:expected_detail) { 'must not contain spaces' }
    it_behaves_like 'processes invalid sort options correctly'
  end

  context 'option is not allowed' do
    let(:params) { { 'sort' => 'user' } }
    let(:error) { RequestHandler::OptionNotAllowedError }
    let(:expected_detail) { 'user is not an allowed sort option' }
    it_behaves_like 'processes invalid sort options correctly'
  end
end
