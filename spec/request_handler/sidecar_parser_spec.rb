# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/sidecar_parser'

describe RequestHandler::SidecarParser do
  shared_examples 'invalid hash' do
    it 'raises an error' do
      expect { subject }.to raise_error(RequestHandler::SchemaValidationError)
    end
  end

  let(:schema) { Dry::Validation.JSON {} }

  it 'fails if there is no data' do
    schema = Dry::Validation.JSON {}
    expect do
      described_class.new(schema:  schema,
                          document:    nil)
    end
      .to raise_error(RequestHandler::MissingArgumentError)
  end

  describe 'schema' do
    let(:schema) do
      Dry::Validation.JSON do
        required(:required, :bool).filled(:bool?)
        optional(:optional, :int).filled(:int?)
        optional(:maybe, :string).maybe(:str?)
      end
    end

    subject do
      described_class.new(
        schema:   schema,
        document: JSON.parse(json)
      ).run
    end

    context 'required is missing' do
      let(:json) do
        { optional: 1, maybe: 'maybe' }.to_json
      end
      it_behaves_like 'invalid hash'
    end

    context 'attr has wrong type' do
      let(:json) do
        { required: 'true', optional: 1, maybe: 'maybe' }.to_json
      end
      it_behaves_like 'invalid hash'
    end

    context 'attr is null' do
      let(:json) do
        { required: 'true', optional: nil, maybe: 'maybe' }.to_json
      end
      it_behaves_like 'invalid hash'
    end
  end
end
