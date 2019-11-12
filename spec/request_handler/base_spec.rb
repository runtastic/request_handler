# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/base'

describe RequestHandler::Base do
  shared_examples 'correct_arguments_passed' do
    it 'passes the right arguments to the handler' do
      expect(tested_parser).to receive(:new).with(expected_args).and_return(runstub)
      expect(testclass.new(request: request).send(tested_method)).to eq(runstub.run)
    end
  end

  shared_examples 'correct_persistence' do
    let(:n) { 2 }
    it 'persists for the same instance' do
      instance = testclass.new(request: request)
      expect(tested_parser).to receive(:new).once.and_return(runstub)
      n.times { instance.send(tested_method) }
    end
    it 'does not persist for different instances' do
      instances = []
      n.times { instances << testclass.new(request: request) }
      expect(tested_parser).to receive(:new).exactly(n).times.and_return(runstub)
      instances.each { |instance| instance.send(tested_method) }
    end
  end

  shared_examples 'default_handling' do
    it 'uses the default values if no value is given' do
      instance = testclass.new(request: request)
      expect(tested_parser).to receive(:new).and_return(runstub)
      expect(instance.send(tested_method)).to eq(tested_defaults[:output])
    end
  end

  shared_examples 'correct_default_handling_hash' do
    context 'without defaults' do
      let(:tested_defaults) { { input: nil, output: runstub.run } }
      it_behaves_like 'default_handling'
    end
    context 'with hash defaults' do
      let(:tested_defaults) { { input: { default_foo: 'bar' }, output: { default_foo: 'bar' }.merge(runstub.run) } }
      it_behaves_like 'default_handling'
    end
    context 'with proc defaults' do
      let(:tested_defaults) do
        { input:  ->(_request) { { default_foo: 'bar' } },
          output: { default_foo: 'bar' }.merge(runstub.run) }
      end
      it_behaves_like 'default_handling'
    end
    context 'with proc using request as defaults' do
      let(:tested_defaults) do
        { input:  ->(request) { { default_foo: request.env['FOO'] } },
          output: { default_foo: 'bar' }.merge(runstub.run) }
      end
      it_behaves_like 'default_handling'
    end
  end
  shared_examples 'correct_default_handling_array' do
    context 'without defaults' do
      it_behaves_like 'default_handling'
    end
    context 'with hash defaults' do
      let(:tested_defaults) do
        {
          input:  %i[test1 test2],
          output: (runstub.run.empty? ? %i[test1 test2] : runstub.run)
        }
      end
      it_behaves_like 'default_handling'
    end
    context 'with proc defaults' do
      let(:tested_defaults) do
        {
          input:  ->(_request) { %i[test1 test2] },
          output: (runstub.run.empty? ? %i[test1 test2] : runstub.run)
        }
      end
      it_behaves_like 'default_handling'
    end
    context 'with proc using request as defaults' do
      let(:tested_defaults) do
        {
          input:  ->(request) { [request.env['FOO'].to_sym] },
          output: (runstub.run.empty? ? [:bar] : runstub.run)
        }
      end
      it_behaves_like 'default_handling'
    end
  end

  let(:params) do
    {
      'url_filter' => 'bar'
    }
  end
  let(:request) do
    instance_double('Rack::Request',
                    params: params,
                    env:    { 'FOO' => 'bar' },
                    body:   StringIO.new('body'))
  end
  let(:runstub) { double('Parser', run: { foo: 'bar' }) }

  context '#filter_params' do
    let(:testclass) do
      opts = tested_options[:input]
      defs = tested_defaults[:input]
      Class.new(RequestHandler::Base) do
        options do
          filter do
            schema 'schema'
            additional_url_filter 'url_filter'
            options(opts)
            defaults(defs)
          end
        end
      end
    end
    let(:expected_args) do
      {
        params:                params,
        schema:                'schema',
        additional_url_filter: 'url_filter',
        schema_options:        tested_options[:output]
      }
    end
    let(:tested_method) { :filter_params }
    let(:tested_parser) { RequestHandler::FilterParser }
    let(:tested_defaults) { { input: nil, output: runstub.run } }
    context 'with a proc as options' do
      let(:tested_options) do
        { input:  ->(_parser, _request) { { body_user_id: 1 } },
          output: { body_user_id: 1 } }
      end
      it_behaves_like 'correct_persistence'
      it_behaves_like 'correct_arguments_passed'
      it_behaves_like 'correct_default_handling_hash'
    end
    context 'with a proc using the request as options' do
      let(:tested_options) do
        { input:  ->(_parser, request) { { foo: request.env['FOO'] } },
          output: { foo: 'bar' } }
      end
      it_behaves_like 'correct_persistence'
      it_behaves_like 'correct_arguments_passed'
      it_behaves_like 'correct_default_handling_hash'
    end
    context 'with a hash options' do
      let(:tested_options) { { input: { foo: 'bar' }, output: { foo: 'bar' } } }
      it_behaves_like 'correct_persistence'
      it_behaves_like 'correct_arguments_passed'
      it_behaves_like 'correct_default_handling_hash'
    end
    context 'with nil as options' do
      let(:tested_options) { { input: nil, output: {} } }
      it_behaves_like 'correct_persistence'
      it_behaves_like 'correct_arguments_passed'
      it_behaves_like 'correct_default_handling_hash'
    end
  end

  context '#page_params' do
    let(:testclass) do
      Class.new(RequestHandler::Base) do
        options do
          page do
            default_size 'default_size'
          end
        end
      end
    end
    let(:expected_args) do
      {
        params:      params,
        page_config: OpenStruct.new(default_size: 'default_size')
      }
    end
    let(:tested_method) { :page_params }
    let(:tested_parser) { RequestHandler::PageParser }
    it_behaves_like 'correct_persistence'
    it_behaves_like 'correct_arguments_passed'
  end

  context '#include_params' do
    let(:runstub) { double('Parser', run: [{ foo: 'bar' }]) }
    let(:testclass) do
      defs = tested_defaults[:input]
      Class.new(RequestHandler::Base) do
        options do
          include_options do
            allowed 'allowed_options'
            default defs
          end
        end
      end
    end
    let(:expected_args) do
      {
        params:               params,
        allowed_options_type: 'allowed_options'
      }
    end
    let(:tested_method) { :include_params }
    let(:tested_parser) { RequestHandler::IncludeOptionParser }
    let(:tested_defaults) { { input: nil, output: runstub.run } }
    it_behaves_like 'correct_persistence'
    it_behaves_like 'correct_arguments_passed'
    it_behaves_like 'correct_default_handling_array'
  end

  context '#sort_params' do
    let(:runstub) { double('Parser', run: [{ foo: 'bar' }]) }
    let(:testclass) do
      defs = tested_defaults[:input]
      Class.new(RequestHandler::Base) do
        options do
          sort_options do
            allowed 'allowed_options'
            default defs
          end
        end
      end
    end
    let(:expected_args) do
      {
        params:               params,
        allowed_options_type: 'allowed_options'
      }
    end
    let(:tested_method) { :sort_params }
    let(:tested_parser) { RequestHandler::SortOptionParser }
    let(:tested_defaults) { { input: nil, output: runstub.run } }
    it_behaves_like 'correct_persistence'
    it_behaves_like 'correct_arguments_passed'
    it_behaves_like 'correct_default_handling_array'
  end

  context '#headers' do
    let(:testclass) do
      Class.new(RequestHandler::Base) do
      end
    end
    let(:expected_args) do
      {
        env: request.env
      }
    end
    let(:tested_method) { :headers }
    let(:tested_parser) { RequestHandler::HeaderParser }
    it_behaves_like 'correct_persistence'
    it_behaves_like 'correct_arguments_passed'
  end

  context '#multipart_params' do
    let(:testclass) do
      Class.new(RequestHandler::Base) do
        options do
          multipart do
            resource :meta do
              schema 'schema'
            end
            resource :file do
            end
          end
        end
      end
    end
    let(:expected_args) do
      {
        request:           request,
        multipart_config: { meta: MultipartResource.new(nil, 'schema'), file: MultipartResource.new }
      }
    end

    let(:tested_method) { :multipart_params }
    let(:tested_parser) { RequestHandler::MultipartsParser }
    let(:tested_options) do
      { input:  ->(_parser, _request) { { body_user_id: 1 } },
        output: { body_user_id: 1 } }
    end
    it_behaves_like 'correct_persistence'
    it_behaves_like 'correct_arguments_passed'
  end

  context '#body_params' do
    let(:testclass) do
      opts = tested_options[:input]
      Class.new(RequestHandler::Base) do
        options do
          body do
            schema 'schema'
            type 'jsonapi'
            options(opts)
          end
        end
      end
    end
    let(:expected_args) do
      {
        request:          request,
        schema:           'schema',
        schema_options:   tested_options[:output],
        type:             'jsonapi'
      }
    end
    let(:tested_method) { :body_params }
    let(:tested_parser) { RequestHandler::BodyParser }
    context 'with a proc as options' do
      let(:tested_options) do
        { input:  ->(_parser, _request) { { body_user_id: 1 } },
          output: { body_user_id: 1 } }
      end
      it_behaves_like 'correct_persistence'
      it_behaves_like 'correct_arguments_passed'
    end
    context 'with a proc using the request as options' do
      let(:tested_options) do
        { input:  ->(_parser, request) { { foo: request.env['FOO'] } },
          output: { foo: 'bar' } }
      end
      it_behaves_like 'correct_persistence'
      it_behaves_like 'correct_arguments_passed'
    end
    context 'with a hash as options' do
      let(:tested_options) { { input: { body_user_id: 1 }, output: { body_user_id: 1 } } }
      it_behaves_like 'correct_persistence'
      it_behaves_like 'correct_arguments_passed'
    end
    context 'with nil as options' do
      let(:tested_options) { { input: nil, output: {} } }
      it_behaves_like 'correct_persistence'
      it_behaves_like 'correct_arguments_passed'
    end
  end

  context '#params' do
    let(:testclass) { Class.new(described_class) }
    it 'tranforms the params dots to undescores before using them' do
      request = instance_double('Rack::Request',
                                params:
                                        {
                                          'foo.bar'      => 'test',
                                          'nested'       => { 'nested.foo.bar' => 'test2' },
                                          'nested.twice' => {
                                            'nested.twice.foo.bar_underscored' => {
                                              'nested.again' => 'test3'
                                            }
                                          }
                                        },
                                env:    {},
                                body:   StringIO.new('body'))
      expect(testclass.new(request: request).send(:params))
        .to eq('foo__bar' => 'test',
               'nested' => { 'nested__foo__bar' => 'test2' },
               'nested__twice' => { 'nested__twice__foo__bar_underscored' => { 'nested__again' => 'test3' } })
    end

    it 'works with both strings and symbols as param keys' do
      request = instance_double('Rack::Request',
                                params:
                                       {
                                         'a.string'                 => 'test',
                                         :a_symbol                  => 'test2',
                                         :'a_symbol_with.separator' => 'omgwtf'
                                       },
                                env:   {},
                                body:  StringIO.new('body'))
      expect(testclass.new(request: request).send(:params))
        .to eq('a__string'                => 'test',
               'a_symbol'                 => 'test2',
               'a_symbol_with__separator' => 'omgwtf')
    end

    it 'transforms nested arrays' do
      request = instance_double('Rack::Request',
                                params:
                                        {
                                          'nested' => [{ 'hash.key.in.array' => 'test2' }, 'normal.array.element']
                                        },
                                env:    {},
                                body:   StringIO.new('body'))
      expect(testclass.new(request: request).send(:params))
        .to eq('nested' => [{ 'hash__key__in__array' => 'test2' }, 'normal.array.element'])
    end
  end

  context 'errorhandling' do
    testclass = Class.new(described_class)
    it 'raises a MissingArgumentError if request is nil' do
      expect { testclass.new(request: nil) }.to raise_error(RequestHandler::MissingArgumentError)
    end
    it 'raises a MissingArgumentError if params is nil' do
      request = instance_double('Rack::Request', params: nil, env: {}, body: '')
      testedhandler = testclass.new(request: request)
      expect { testedhandler.send(:params) }.to raise_error(RequestHandler::MissingArgumentError)
    end
    it 'raises a ExternalArgumentError if params is not a Hash' do
      request = instance_double('Rack::Request', params: 'Foo', env: {}, body: '')
      testedhandler = testclass.new(request: request)
      expect { testedhandler.send(:params) }.to raise_error(RequestHandler::ExternalArgumentError)
    end
  end
  context 'missing options' do
    let(:testclass) do
      Class.new(RequestHandler::Base) do
        options do
        end
      end
    end

    let(:request) { instance_double('Rack::Request', params: {}, env: {}, body: {}) }
    let(:handler) { testclass.new(request: request) }

    it 'fails for a missing filter schema' do
      expect { handler.send(:filter_params) }.to raise_error(RequestHandler::NoConfigAvailableError)
    end
    it 'fails for a missing page options' do
      expect { handler.send(:page_params) }.to raise_error(RequestHandler::NoConfigAvailableError)
    end
    it 'fails for a missing allowed include options' do
      expect { handler.send(:include_params) }.to raise_error(RequestHandler::NoConfigAvailableError)
    end
    it 'fails for a missing allowed sort options' do
      expect { handler.send(:sort_params) }.to raise_error(RequestHandler::NoConfigAvailableError)
    end
    it 'fails for a missing body schema' do
      expect { handler.send(:body_params) }.to raise_error(RequestHandler::NoConfigAvailableError)
    end
    it "doesn't fails for a missing required fieldset params" do
      config = handler.send(:config)
      resource = OpenStruct.new(posts: Dry::Types['strict.string'].enum('foo', 'bar'))
      config.fieldsets = Fieldsets.new(resource)
      expect { handler.send(:fieldsets_params) }.not_to raise_error(RequestHandler::NoConfigAvailableError)
    end

    it 'fails for a missing allowed fieldset params' do
      config = handler.send(:config)
      config.fieldsets = Fieldsets.new(nil, ['Foo'])
      expect { handler.send(:fieldsets_params) }.to raise_error(RequestHandler::NoConfigAvailableError)
    end
  end
end
