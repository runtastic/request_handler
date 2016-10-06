# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/base"
shared_examples "correct_arguments_passed" do
  it "passes the right arguments to the handler" do
    expect(tested_handler).to receive(:new).with(expected_result).and_return(runstub)
    testclass.new(request: request).send(tested_method)
  end
end
