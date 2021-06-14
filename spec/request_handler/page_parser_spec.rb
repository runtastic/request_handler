# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/page_parser'
describe RequestHandler::PageParser do
  shared_examples 'valid input' do
    it 'uses the value from the params if its within the limits' do
      handler = RequestHandler::PageParser.new(params: params, page_config: lookup!(config, 'page'))
      expect(handler.run).to eq(output)
    end
  end
  let(:jsonapi_error) { anything }
  shared_examples 'input that causes an error' do
    it 'raises an error' do
      handler = RequestHandler::PageParser.new(params: params, page_config: lookup!(config, 'page'))
      expect { handler.run }.to raise_error(error) do |raised_error|
        expect(raised_error.errors).to contain_exactly(jsonapi_error)
      end
    end
  end
  shared_examples 'input that causes a warning' do
    it 'prints a warning' do
      handler = RequestHandler::PageParser.new(params: params, page_config: lookup!(config, 'page'))
      expect(RequestHandler.configuration.logger).to receive(:warn).with(warning)
      expect(handler.run).to eq(output)
    end
  end

  let(:config) do
    build_docile(RequestHandler::Builder::OptionsBuilder, &block)
  end

  let(:block) do
    proc do
      page do
        default_size 15
        max_size 50

        resource :posts do
          default_size 30
          max_size 50
        end

        resource :users do
          default_size 20
          max_size 40
        end
      end
    end
  end

  context 'valid params and config' do
    context 'size from the params is below the limit' do
      let(:params) do
        {
          'page' => {
            'posts__size'   => '34',
            'posts__number' => '2',
            'users__size'   => '25',
            'users__number' => '2'
          }
        }
      end
      let(:output) do
        {
          number:       1,
          size:         15,
          posts__number: 2,
          posts__size:   34,
          users__number: 2,
          users__size:   25
        }
      end
      it_behaves_like 'valid input'
    end

    context 'param requests a size bigger than allowed' do
      let(:params) do
        {
          'page' => {
            'posts__size'   => '34',
            'posts__number' => '2',
            'users__size'   => '100',
            'users__number' => '2'
          }
        }
      end
      let(:output) do
        {
          number:       1,
          size:         15,
          posts__number: 2,
          posts__size:   34,
          users__number: 2,
          users__size:   40
        }
      end
      it_behaves_like 'valid input'
    end
  end
  context 'invalid params and valid config' do
    context 'size not defined in the params' do
      let(:params) do
        { 'page' => {
          'users__size'   => '39',
          'users__number' => '2'
        } }
      end
      let(:output) do
        { number:       1,
          size:         15,
          posts__number: 1,
          posts__size:   30,
          users__number: 2,
          users__size:   39 }
      end
      it_behaves_like 'valid input'
    end

    let(:jsonapi_error) do
      {
        code: 'INVALID_QUERY_PARAMETER',
        status: '400',
        detail: 'must be a positive integer',
        source: { parameter: expected_param }
      }
    end

    context 'number is set to a non integer string' do
      let(:error) { RequestHandler::PageParamsError }
      let(:params) do
        { 'page' => {
          'users__size'   => '40',
          'users__number' => 'asdf'
        } }
      end
      let(:expected_param) { 'page[users.number]' }
      it_behaves_like 'input that causes an error'
    end

    context 'number is set to a negative string' do
      let(:error) { RequestHandler::PageParamsError }
      let(:params) do
        { 'page' => {
          'users__size'   => '40',
          'users__number' => '-20'
        } }
      end
      let(:expected_param) { 'page[users.number]' }
      it_behaves_like 'input that causes an error'
    end

    context 'size is set to a negative string' do
      let(:error) { RequestHandler::PageParamsError }
      let(:params) do
        { 'page' => {
          'users__size'   => '-40',
          'users__number' => '20'
        } }
      end
      let(:expected_param) { 'page[users.size]' }
      it_behaves_like 'input that causes an error'
    end

    context 'size is set to a non integer string' do
      let(:error) { RequestHandler::PageParamsError }
      let(:params) do
        { 'page' => {
          'users__size'   => 'asdf',
          'users__number' => '2'
        } }
      end
      let(:expected_param) { 'page[users.size]' }
      it_behaves_like 'input that causes an error'
    end
  end
  context 'configuration problems' do
    let(:context_config) do
      build_docile(RequestHandler::Builder::OptionsBuilder, &block)
    end

    let(:block) do
      proc do
        page do
          default_size 15
          max_size 50
          resource :posts do
            default_size 30
            max_size 40
          end
        end
      end
    end

    let(:params) do
      {
        'page' => {
          'size'         => '20',
          'number'       => '2',
          'posts__size'   => '500',
          'posts__number' => '2'
        }
      }
    end

    context 'default_size is not an Integer' do
      let(:config) do
        context_config.page.posts.default_size = '123'
        context_config
      end
      let(:error) { RequestHandler::InternalArgumentError }
      it_behaves_like 'input that causes an error'
    end

    context 'max_size is not an Integer' do
      let(:config) do
        context_config.page.posts.max_size = '123'
        context_config
      end
      let(:error) { RequestHandler::InternalArgumentError }
      it_behaves_like 'input that causes an error'
    end

    context 'default size is not set' do
      let(:config) do
        context_config.page.posts.default_size = nil
        context_config
      end
      let(:error) { RequestHandler::NoConfigAvailableError }
      it_behaves_like 'input that causes an error'
    end

    context 'default size is not set on the top level' do
      let(:config) do
        context_config.page.default_size = nil
        context_config
      end
      let(:error) { RequestHandler::NoConfigAvailableError }
      it_behaves_like 'input that causes an error'
    end

    context 'both sizes are not set' do
      let(:config) do
        context_config.page.posts.max_size = nil
        context_config.page.posts.default_size = nil
        context_config
      end
      let(:error) { RequestHandler::NoConfigAvailableError }
      it_behaves_like 'input that causes an error'
    end

    context 'both sizes are not set on the top level' do
      let(:config) do
        context_config.page.max_size = nil
        context_config.page.default_size = nil
        context_config
      end
      let(:error) { RequestHandler::NoConfigAvailableError }
      it_behaves_like 'input that causes an error'
    end

    context 'max_size is not set' do
      let(:config) do
        context_config.page.posts.max_size = nil
        context_config
      end
      let(:params) do
        {
          'page' => {
            'posts__size'   => '500',
            'posts__number' => '2'
          }
        }
      end
      let(:output) do
        {
          number:       1,
          size:         15,
          posts__number: 2,
          posts__size:   500
        }
      end
      let(:warning) { 'posts max_size config not set' }
      it_behaves_like 'input that causes a warning'
    end

    context 'client sends unknown prefix' do
      let(:config) { context_config }
      let(:params) do
        {
          'page' => {
            'foo__size' => '3'
          }
        }
      end
      let(:output) do
        {
          number:       1,
          size:         15,
          posts__number: 1,
          posts__size:   30
        }
      end
      let(:warning) { 'client sent unknown option ["foo.size"]' }
      it_behaves_like 'input that causes a warning'
    end
  end

  it 'raises an error if page config is set to nil' do
    expect { described_class.new(params: {}, page_config: nil) }
      .to raise_error(RequestHandler::MissingArgumentError)
  end

  it 'raises an error if params is set to nil' do
    expect { described_class.new(params: nil, page_config: {}) }
      .to raise_error(RequestHandler::MissingArgumentError)
  end
end
