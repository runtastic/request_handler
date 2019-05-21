# frozen_string_literal: true

require 'spec_helper'
describe RequestHandler do
  shared_examples 'it validates headers' do
    subject(:to_dto) { testclass.new(request: request).to_dto }
    let(:request) { build_mock_request(params: {}, headers: headers, body: '') }
    context 'HeaderParser' do
      let(:testclass) do
        Class.new(RequestHandler::Base) do
          def to_dto
            OpenStruct.new(
              headers: headers
            )
          end
        end
      end
      context 'without headers' do
        let(:headers) { nil }
        it { expect { to_dto }.to raise_error(RequestHandler::MissingArgumentError) }
      end
      context 'with headers set correctly' do
        let(:headers) { { 'HTTP_APP_KEY' => 'some.app.key', 'HTTP_USER_ID' => '345' } }
        it { expect(to_dto).to eq(OpenStruct.new(headers: { app_key: 'some.app.key', user_id: '345' })) }
      end
    end
  end

  context 'with dry engine' do
    include_context 'with dry validation engine' do
      it_behaves_like 'it validates headers'
    end
  end

  context 'with definition engine' do
    include_context 'with definition validation engine' do
      it_behaves_like 'it validates headers'
    end
  end
end
