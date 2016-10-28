# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/schema_handler"
describe Dry::RequestHandler::SchemaHandler do
  shared_examples "handles valid input data correctly" do
    it "generates the expected output with valid input and without schema options" do
      handler = testclass.new(schema: schema_without_options, data: data)
      expect(handler.run).to eq(data)
    end
    it "generates the expected output with valid input and with schema options" do
      handler = testclass.new(schema: schema_with_options, schema_options: { testoption: 5 },  data: data)
      expect(handler.run).to eq(data)
    end
  end
  shared_examples "handles invalid input data correctly" do
    it "raises an error with invalid input and without schema options" do
      handler = testclass.new(schema: schema_without_options, data: data)
      expect { handler.run }.to raise_error(error)
    end
    it "raises an error with invalid input and with schema options" do
      handler = testclass.new(schema: schema_without_options, schema_options: { testoption: 5 }, data: data)
      expect { handler.run }.to raise_error(error)
    end
  end

  let(:schema_without_options) do
    Dry::Validation.Schema do
      required(:test1).filled
      required(:test2).filled
    end
  end
  let(:schema_with_options) do
    Dry::Validation.Schema do
      configure do
        option :testoption
      end
      required(:test1).filled
      required(:test2).value(eql?: testoption)
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

  it "fails if schema is nil" do
    expect { described_class.new(schema: nil) }.to raise_error(Dry::RequestHandler::MissingArgumentError)
  end

  it "fails for an invalid schema" do
    expect { described_class.new(schema: "foo") }.to raise_error(Dry::RequestHandler::InternalArgumentError)
  end

  it "fails if schema_options is nil" do
    expect { described_class.new(schema: schema_without_options, schema_options: nil) }
      .to raise_error(Dry::RequestHandler::MissingArgumentError)
  end

  it_behaves_like "handles valid input data correctly" do
    let(:data) { { test1: "t1", test2: 5 } }
  end

  context "data is mising something required in the schema" do
    let(:data) { { test1: "t1" } }
    let(:error) { Dry::RequestHandler::SchemaValidationError }
    it_behaves_like "handles invalid input data correctly"
  end

  context "data is missing completely" do
    let(:data) { nil }
    let(:error) { Dry::RequestHandler::MissingArgumentError }
    it_behaves_like "handles invalid input data correctly"
  end
end
