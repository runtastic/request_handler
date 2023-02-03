# frozen_string_literal: true

require "spec_helper"

describe RequestHandler::BaseError do
  describe "message" do
    subject(:message) { described_class.new(errors).message }

    let(:errors) { { foo: "bar", meh: "muh" } }

    it { is_expected.to eql("foo: bar, meh: muh") }
  end
end
