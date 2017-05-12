# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/include_option_parser'
describe RequestHandler::IncludeOptionParser do
  let(:handler) do
    options_type = Dry::Types['strict.string'].enum('user', 'email', 'user__posts')
    described_class.new(params:               params,
                        allowed_options_type: options_type)
  end
  shared_examples 'proccesses valid options correctly' do
    it 'it returns an array of include options' do
      expect(handler.run).to eq output
    end
  end
  shared_examples 'proccesses invalid options correctly' do
    it 'raises an error if the include options are invalid' do
      expect { handler.run }.to raise_error(error)
    end
  end

  context 'option is allowed' do
    let(:params) { { 'include' => 'user,email' } }
    let(:output) { %i[user email] }
    it_behaves_like 'proccesses valid options correctly'
  end

  context 'nested attributes are correctly transformed' do
    let(:params) { { 'include' => 'user,user.posts' } }
    let(:output) { %i[user user__posts] }
    it_behaves_like 'proccesses valid options correctly'
  end

  context 'include param is not set' do
    let(:params) { {} }
    let(:output) { [] }
    it_behaves_like 'proccesses valid options correctly'
  end

  context 'no include options are specified' do
    let(:params) { { 'include' => '' } }
    let(:output) { [] }
    let(:error) { RequestHandler::ExternalArgumentError }
    it_behaves_like 'proccesses invalid options correctly'
  end

  context 'options contain a space' do
    let(:params) { { 'include' => 'user, email' } }
    let(:error) { RequestHandler::ExternalArgumentError }
    it_behaves_like 'proccesses invalid options correctly'
  end

  context 'option is not allowed' do
    let(:params)  { { 'include' => 'user,password' } }
    let(:error) { RequestHandler::OptionNotAllowedError }
    it_behaves_like 'proccesses invalid options correctly'
  end
end
