# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/base"
shared_examples "correct_persistence" do
  let(:n) { 2 }

  it "persists for the same instance" do
    instance = testclass.new(request: request)
    expect(tested_handler).to receive(:new).once.and_return(runstub)
    n.times { instance.send(tested_method) }
  end

  it "does not persist for different instances" do
    instances = []
    n.times { instances << testclass.new(request: request) }
    expect(tested_handler).to receive(:new).exactly(n).times.and_return(runstub)
    instances.each { |instance| instance.send(tested_method) }
  end
end
