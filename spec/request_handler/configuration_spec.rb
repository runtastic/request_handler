# frozen_string_literal: true
describe RequestHandler do
  it 'has a working logger configured' do
    expect(RequestHandler.configuration.logger).to respond_to(:warn)
  end
end
