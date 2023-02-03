# frozen_string_literal: true

require "spec_helper"
require "request_handler/document_parser"

describe RequestHandler::DocumentParser do
  let(:handler) do
    described_class.new(type: type, document: {}, schema: {})
  end

  context "jsonapi" do
    let(:type) { "jsonapi" }

    it "calls JsonApiDocumentParser" do
      expect(RequestHandler::JsonApiDocumentParser).to receive(:new)
      handler
    end
  end

  context "nil" do
    let(:type) { nil }

    it "calls JsonApiDocumentParser as default" do
      expect(RequestHandler::JsonApiDocumentParser).to receive(:new)
      handler
    end
  end

  context "json" do
    let(:type) { "json" }

    it "calls JsonParser" do
      expect(RequestHandler::JsonParser).to receive(:new)
      handler
    end
  end

  context "undefined" do
    let(:type) { "undefined" }

    it "raises error" do
      expect { handler }.to raise_error(RequestHandler::InternalArgumentError)
    end
  end
end
