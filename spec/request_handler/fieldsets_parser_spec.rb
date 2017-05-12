# frozen_string_literal: true

require 'spec_helper'
describe RequestHandler::FieldsetsParser do
  let(:opts) do
    Confstruct::Configuration.new do
      fieldsets do
        allowed do
          posts Dry::Types['strict.string'].enum('awesome', 'samples')
          photos Dry::Types['strict.string'].enum('foo', 'bar')
        end
        required [:posts]
      end
    end
  end
  shared_examples 'returns fieldsets' do
    let(:allowed) { opts.lookup!('fieldsets.allowed') }
    let(:required) { opts.lookup!('fieldsets.required') }
    let(:expected) { {} }
    it 'returns the hash' do
      expect(described_class.new(params: params, allowed: allowed, required: required).run)
        .to eq(expected)
    end
  end
  shared_examples 'fails' do
    let(:error) { RequestHandler::ExternalArgumentError }
    it 'raises an error' do
      expect do
        described_class.new(params:   params,
                            allowed:  opts.lookup!('fieldsets.allowed'),
                            required: opts.lookup!('fieldsets.required')).run
      end
        .to raise_error(error)
    end
  end
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
      opts.required = %i[posts photos]
    end
    it_behaves_like 'returns fieldsets' do
      let(:params) { { 'fields' => { 'posts' => 'awesome', 'photos' => 'foo' } } }
      let(:expected) { { posts: [:awesome], photos: [:foo] } }
    end
  end

  context 'failing' do
    context 'required type is not set in the request' do
      it_behaves_like 'fails' do
        let(:params) { { 'fields' => { 'photos' => 'bar' } } }
      end
    end
    context 'one required type is not set in the request' do
      before do
        opts.required = %i[posts photos]
      end
      it_behaves_like 'fails' do
        let(:params) { { 'fields' => { 'photos' => 'bar' } } }
      end
    end
    context 'params are empty but there is a required type' do
      it_behaves_like 'fails' do
        let(:params) { {} }
      end
    end
    context 'invalid type' do
      it_behaves_like 'fails' do
        let(:params) { { 'fields' => { 'post' => 'samples' } } }
        let(:error) { RequestHandler::OptionNotAllowedError }
      end
    end
    context 'invalid option for type' do
      it_behaves_like 'fails' do
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
