# frozen_string_literal: true

require 'spec_helper'
describe RequestHandler::FieldsetsParser do
  let(:opts) do
    build_docile(RequestHandler::Builder::OptionsBuilder, &block)
  end

  let(:block) do
    proc do
      fieldsets do
        allowed do
          resource :posts, Dry::Types['strict.string'].enum('awesome', 'samples')
          resource :photos, Dry::Types['strict.string'].enum('foo', 'bar')
          resource :videos, true
          resource :musicfiles, false
        end
        required [:posts]
      end
    end
  end

  let(:allowed) { lookup!(opts, 'fieldsets.allowed') }
  let(:required) { lookup!(opts, 'fieldsets.required') }
  subject(:run) { described_class.new(params: params, allowed: allowed, required: required).run }

  shared_examples 'returns fieldsets' do
    let(:expected) { {} }
    it 'returns the hash' do
      expect(run).to eq(expected)
    end
  end

  shared_examples 'fails' do
    let(:error) { RequestHandler::FieldsetsParamsError }
    let(:jsonapi_error) { {} }
    it 'raises an error' do
      expect { run }.to raise_error(error) do |raised_error|
        expect(raised_error.errors).to contain_exactly(jsonapi_error)
      end
    end
  end

  context 'fieldset tests' do
    context 'no fieldset settings in the config or request' do
      it_behaves_like 'returns fieldsets' do
        let(:allowed) { {} }
        let(:required) { [] }
        let(:params) { {} }
      end
    end

    context 'fieldset settings and the parameter are set' do
      it_behaves_like 'returns fieldsets' do
        let(:params) { { 'fields' => { 'posts' => 'awesome' } } }
        let(:expected) { { posts: [:awesome] } }
      end
    end

    context 'fieldset settings and multiple parameters are set' do
      it_behaves_like 'returns fieldsets' do
        let(:params)  { { 'fields' => { 'posts' => 'awesome,samples' } } }
        let(:expected) { { posts: %i[awesome samples] } }
      end
    end

    context 'fieldset settings and a required and an optional parameter are set' do
      it_behaves_like 'returns fieldsets' do
        let(:params) { { 'fields' => { 'posts' => 'awesome', 'photos' => 'foo' } } }
        let(:expected) { { posts: [:awesome], photos: [:foo] } }
      end
    end

    context 'fieldset settings and the required parameters are set' do
      before do
        opts.fieldsets.required = %i[posts photos]
      end
      it_behaves_like 'returns fieldsets' do
        let(:params) { { 'fields' => { 'posts' => 'awesome', 'photos' => 'foo' } } }
        let(:expected) { { posts: [:awesome], photos: [:foo] } }
      end
    end

    context 'invalid fieldset wich fails because of unrecognized field in posts' do
      it_behaves_like 'fails' do
        let(:jsonapi_error) do
          {
            code: 'INVALID_QUERY_PARAMETER',
            status: '400',
            detail: "allowed fieldset does not include 'good'",
            source: { parameter: 'fields[posts]' }
          }
        end
        let(:params) { { 'fields' => { 'posts' => 'awesome,good' } } }
      end
    end
  end

  context 'fieldset types tests' do
    context 'valid fieldset wich return all parameters because fieldset is set to true in RequestHandler config' do
      it_behaves_like 'returns fieldsets' do
        let(:params) { { 'fields' => { 'posts' => 'awesome', 'videos' => 'nr1,nr2,nr3' } } }
        let(:expected) { { posts: [:awesome], videos: %i[nr1 nr2 nr3] } }
      end
    end

    context 'invalid fieldset wich fails because of unrecognized field in posts' do
      it_behaves_like 'fails' do
        let(:jsonapi_error) do
          {
            code: 'INVALID_QUERY_PARAMETER',
            status: '400',
            detail: "allowed fieldset does not include 'post1'",
            source: { parameter: 'fields[posts]' }
          }
        end
        let(:params) { { 'fields' => { 'posts' => 'post1,post2', 'videos' => 'nr1,nr2' } } }
      end
    end

    context 'invalid fieldset which fails because fieldset "musicfiles" is set to false in RequestHandler config' do
      it_behaves_like 'fails' do
        let(:params) do
          { 'fields' => { 'videos' => 'video1,video2,video3',
                          'musicfiles' => 'nr1,nr2' } }
        end
        let(:jsonapi_error) do
          {
            code: 'INVALID_QUERY_PARAMETER',
            status: '400',
            detail: "fieldset for 'musicfiles' not allowed",
            source: { parameter: 'fields[musicfiles]' }
          }
        end
        let(:error) { RequestHandler::OptionNotAllowedError }
      end
    end
    context 'invalid fieldset which fails because fieldset "games" is not set in RequestHandler config' do
      it_behaves_like 'fails' do
        let(:params) do
          { 'fields' => { 'videos' => 'video1,video2,video3',
                          'games' => 'nr1,nr2' } }
        end
        let(:jsonapi_error) do
          {
            code: 'INVALID_QUERY_PARAMETER',
            status: '400',
            detail: "fieldset for 'games' not allowed",
            source: { parameter: 'fields[games]' }
          }
        end
        let(:error) { RequestHandler::OptionNotAllowedError }
      end
    end
  end

  context 'failing' do
    context 'required type is not set in the request' do
      it_behaves_like 'fails' do
        let(:jsonapi_error) do
          {
            code: 'MISSING_QUERY_PARAMETER',
            status: '400',
            detail: 'missing required parameter fields[posts]',
            source: { parameter: '' }
          }
        end
        let(:params) { { 'fields' => { 'photos' => 'bar' } } }
      end
    end
    context 'one required type is not set in the request' do
      before do
        opts.fieldsets.required = %i[posts photos]
      end
      it_behaves_like 'fails' do
        let(:jsonapi_error) do
          {
            code: 'MISSING_QUERY_PARAMETER',
            status: '400',
            detail: 'missing required parameter fields[posts]',
            source: { parameter: '' }
          }
        end
        let(:params) { { 'fields' => { 'photos' => 'bar' } } }
      end
    end
    context 'params are empty but there is a required type' do
      it_behaves_like 'fails' do
        let(:jsonapi_error) do
          {
            code: 'MISSING_QUERY_PARAMETER',
            status: '400',
            detail: 'missing required parameter fields[posts]',
            source: { parameter: '' }
          }
        end
        let(:params) { {} }
      end
    end
    context 'invalid type' do
      it_behaves_like 'fails' do
        let(:params) { { 'fields' => { 'post' => 'samples' } } }
        let(:jsonapi_error) do
          {
            code: 'INVALID_QUERY_PARAMETER',
            status: '400',
            detail: "fieldset for 'post' not allowed",
            source: { parameter: 'fields[post]' }
          }
        end
        let(:error) { RequestHandler::OptionNotAllowedError }
      end
    end
    context 'invalid option for type' do
      it_behaves_like 'fails' do
        let(:jsonapi_error) do
          {
            code: 'INVALID_QUERY_PARAMETER',
            status: '400',
            detail: "allowed fieldset does not include 'bars'",
            source: { parameter: 'fields[posts]' }
          }
        end
        let(:params) { { 'fields' => { 'posts' => 'bars' } } }
      end
    end

    context 'invalid settings' do
      it 'fails if an allowed type is not a Enum' do
        opts.fieldsets.allowed.posts = 'foo'
        expect { described_class.new(params: {}, allowed: opts.fieldsets.allowed, required: [:posts]) }
          .to raise_error(RequestHandler::InternalArgumentError)
      end

      it 'fails if required is not an Array' do
        expect { described_class.new(params: {}, allowed: opts.fieldsets.allowed, required: 'foo') }
          .to raise_error(RequestHandler::InternalArgumentError)
      end
    end
  end
end
