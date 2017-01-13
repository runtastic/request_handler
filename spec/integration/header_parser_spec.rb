# frozen_string_literal: true
require 'spec_helper'
describe RequestHandler do
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
    it 'raises a MissingArgumentError if the headers are not set' do
      request = build_mock_request(params: {}, headers: nil, body: '')
      testhandler = testclass.new(request: request)
      expect { testhandler.to_dto }.to raise_error(RequestHandler::MissingArgumentError)
    end
    it 'works if the headers are set corectly' do
      request = build_mock_request(params: {}, headers: {
                                     'HTTP_APP_KEY' => 'some.app.key',
                                     'HTTP_USER_ID' => '345'
                                   },
                                   body: '')
      testhandler = testclass.new(request: request)
      expect(testhandler.to_dto).to eq(OpenStruct.new(headers: { app_key: 'some.app.key',
                                                                 user_id: '345' }))
    end
  end
end
