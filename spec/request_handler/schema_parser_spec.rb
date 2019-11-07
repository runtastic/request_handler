# frozen_string_literal: true

require 'spec_helper'
require 'request_handler/schema_parser'
describe RequestHandler::SchemaParser do
  shared_examples 'handles valid input data correctly' do
    it 'generates the expected output with valid input and without schema options' do
      handler = testclass.new(schema: schema_without_options, data: data)
      expect(handler.run).to eq(output)
    end
    it 'generates the expected output with valid input and with schema options' do
      handler = testclass.new(schema: schema_with_options, schema_options: { testoption: 5 }, data: data)
      expect(handler.run).to eq(output)
    end
  end
  shared_examples 'handles invalid input data correctly' do
    it 'raises an error with invalid input and without schema options' do
      handler = testclass.new(schema: schema_without_options, data: data)
      expect { handler.run }.to raise_error(error)
    end
    it 'raises an error with invalid input and with schema options' do
      handler = testclass.new(schema: schema_with_options, schema_options: { testoption: 5 }, data: data)
      expect { handler.run }.to raise_error(error)
    end
  end

  module Types
    require 'dry-types'
    include Dry::Types.module
    ArrayFromCSV = Strict::Array.constructor do |val|
      val.is_a?(::Array) ? val : val.to_s.split(',')
    end
    SupportedFilterKeys = Strict::String.enum('some', 'none')
  end

  let(:schema_without_options) do
    Dry::Schema.Params do
      required(:test1).filled(:string)
      required(:test2).filled(:integer, gt?: 0)
      optional(:filter_type_in).filled(Types::ArrayFromCSV).each(Types::SupportedFilterKeys)
    end
  end
  let(:schema_with_options) do
    Class.new(Dry::Validation::Contract) do
      option :testoption
      params do
        required(:test1).filled(:string)
        required(:test2).filled(:integer)
        optional(:filter_type_in).filled(Types::ArrayFromCSV).each(Types::SupportedFilterKeys)
      end
      rule(:test2) do
        key.failure('invalid test_2') unless values[:test2] == testoption
      end
    end
  end
  let(:testclass) do
    Class.new(described_class) do
      def initialize(schema:, schema_options: {}, data: nil)
        super(schema: schema, schema_options: schema_options)
        @data = data
      end

      def run
        validate_schema(@data)
      end
    end
  end

  it 'fails if schema is nil' do
    expect { described_class.new(schema: nil) }.to raise_error(RequestHandler::MissingArgumentError)
  end

  it 'fails for an invalid schema' do
    expect { described_class.new(schema: 'foo') }.to raise_error(RequestHandler::InternalArgumentError)
  end

  it 'fails if schema_options is nil' do
    expect { described_class.new(schema: schema_without_options, schema_options: nil) }
      .to raise_error(RequestHandler::MissingArgumentError)
  end

  it_behaves_like 'handles valid input data correctly' do
    let(:data) { { test1: 't1', test2: '5', filter_type_in: 'some' } }
    let(:output) { { test1: 't1', test2: 5, filter_type_in: ['some'] } }
  end

  context 'data is mising something required in the schema' do
    let(:data) { { test1: 't1' } }
    let(:error) { RequestHandler::SchemaValidationError }
    it_behaves_like 'handles invalid input data correctly'
  end

  context 'data is missing completely' do
    let(:data) { nil }
    let(:error) { RequestHandler::MissingArgumentError }
    it_behaves_like 'handles invalid input data correctly'
  end

  context 'filter value is invalid' do
    let(:data) { { test1: 't1', test2: '5', filter_type_in: ['invalid'] } }
    let(:error) { RequestHandler::SchemaValidationError }
    it_behaves_like 'handles invalid input data correctly'
  end

  context 'filter type is invalid' do
    let(:data) { { test1: 't1', test2: '5', filter_type_in: 'invalid' } }
    let(:error) { RequestHandler::SchemaValidationError }
    it_behaves_like 'handles invalid input data correctly'
  end

  context 'data keys get deep_symbolized when schema rules are symbols' do
    let(:schema_without_options) do
      Dry::Schema.Params do
        required(:simple).filled(:integer)
        optional(:nested).maybe(%i[nil hash]) do
          schema do
            required(:attr1).filled(:string)
            required(:attr2).filled(:string)
          end
        end
      end
    end

    let(:data)   { { 'simple' => 5, 'nested' => { 'attr1' => 'a1', 'attr2' => 'a2' } } }
    let(:output) { { simple: 5, nested: { attr1: 'a1', attr2: 'a2' } } }

    it 'transforms keys' do
      handler = testclass.new(schema: schema_without_options, data: data)
      expect(handler.run).to eq(output)
    end
  end
end
