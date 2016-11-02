# frozen_string_literal: true
describe Dry::RequestHandler do
  it "has a working logger configured" do
    expect(Dry::RequestHandler.configuration.logger).to respond_to(:warn)
  end
end
