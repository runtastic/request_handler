# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/schema_handler"
describe Dry::RequestHandler::SchemaHandler do
  let(:schema) do
    Dry::Validation.Schema do
      required(:test1).filled
      required(:test2).filled
    end
  end
  it "fails if schema is nil" do
    expect { described_class.new(schema: nil) }.to raise_error(ArgumentError)
  end
  it "fails if schema_options is nil" do
    expect { described_class.new(schema: schema, schema_options: nil) }.to raise_error(ArgumentError)
  end
  context("without options") do
    it "generates the expected output with a valid input" do
      valid_input = { test1: "t1", test2: "t2" }
      handler = described_class.new(schema: schema)
      expect(handler.run(valid_input)).to eq(valid_input)
    end

    it "fails with an invalid input" do
      invalid_input = { test1: "t1" }
      handler = described_class.new(schema: schema)
      expect { handler.run(invalid_input) }.to raise_error(RuntimeError) # TODO: Add Real Error here
    end
    it "fails if schema is nil" do
      expect { described_class.new(schema: nil) }.to raise_error(ArgumentError)
    end
    it "fails if schema_options is nil" do
      expect { described_class.new(schema: schema, schema_options: nil) }.to raise_error(ArgumentError)
    end
  end
  context("with options") do
    let(:schema) do
      Dry::Validation.Schema do
        configure do
          option :testoption
        end
        required(:test1).filled
        required(:test2).value(eql?: testoption)
      end
    end
    it "generates the expected output with a valid input" do
      valid_input = { test1: "t1", test2: 5 }
      handler = described_class.new(schema: schema, schema_options: { testoption: 5 })
      expect(handler.run(valid_input)).to eq(valid_input)
    end

    it "fails with no options given and an invalid input" do
      invalid_input = { test1: "t1", test2: 1  }
      handler = described_class.new(schema: schema, schema_options: { testoption: 5 })
      expect { handler.run(invalid_input) }.to raise_error(RuntimeError) # TODO: Add Real Error here
    end
  end
end
