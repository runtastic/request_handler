# frozen_string_literal: true
describe Dry::RequestHandler do
  it "has a working logger configured" do
    expect(Dry::RequestHandler.configuration.logger).to receive(:warn).with("test")
    Dry::RequestHandler.configuration.logger.warn("test")
  end
end
