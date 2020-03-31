# frozen_string_literal: true

require 'spec_helper'
describe RequestHandler do
  shared_examples 'it sets the headers' do
    subject(:to_dto) { class_without_headers_schema.new(request: request).to_dto }
    let(:request) { build_mock_request(params: {}, headers: headers, body: '') }

    context 'HeaderParser' do
      let(:class_without_headers_schema) do
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

  shared_examples 'it validates the headers' do
    subject(:to_dto) { class_with_headers_schema.new(request: request).to_dto }
    let(:request) { build_mock_request(params: {}, headers: headers, body: '') }

    context 'HeaderParser' do
      let(:class_with_headers_schema) do
        Class.new(RequestHandler::Base) do
          options do
            headers do
              schema(Dry::Schema.Params do
                required(:client_id).filled(:integer)
              end)
            end
          end

          def to_dto
            OpenStruct.new(
              headers: headers
            )
          end
        end
      end

      context 'when the headers are invalid' do
        let(:headers) { { 'HTTP_CLIENT_ID' => 'abc' } }

        it 'raises an exception' do
          expect { to_dto }.to raise_error(RequestHandler::ExternalArgumentError) do |raised_error|
            expect(raised_error.errors).to eq(
              [
                {
                  status: '400',
                  code: 'INVALID_HEADER',
                  detail: 'must be an integer',
                  source: { header: 'Client-Id' }
                }
              ]
            )
          end
        end
      end

      context 'when the headers are missing' do
        let(:headers) { {} }

        it 'raises an exception' do
          expect { to_dto }.to raise_error(RequestHandler::ExternalArgumentError) do |raised_error|
            expect(raised_error.errors).to eq(
              [
                {
                  status: '400',
                  code: 'MISSING_HEADER',
                  detail: 'is missing',
                  source: { header: 'Client-Id' }
                }
              ]
            )
          end
        end
      end

      context 'when the headers are valid' do
        let(:headers) { { 'HTTP_CLIENT_ID' => '0001234' } }

        it 'does not raise an exception' do
          expect { to_dto }.to_not raise_error(RequestHandler::ExternalArgumentError)
        end

        it 'sets the headers' do
          expect(to_dto).to eq(OpenStruct.new(headers: { client_id: 1234 }))
        end
      end
    end
  end

  context 'with dry engine' do
    include_context 'with dry validation engine' do
      it_behaves_like 'it sets the headers'
      it_behaves_like 'it validates the headers'
    end
  end

  context 'with definition engine' do
    include_context 'with definition validation engine' do
      it_behaves_like 'it sets the headers'
      it_behaves_like 'it validates the headers'
    end
  end
end
