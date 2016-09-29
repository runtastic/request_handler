# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/sort_option_handler"
describe Dry::RequestHandler::SortOptionHandler do
  it "return the right hash for one ascending sort order for a allowed option" do
    params = { "sort" => "id" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("id"))
    expect(handler.run).to eq([{ id: :asc }])
  end
  it "return the right hash for one ascending sort order for a allowed option" do
    params = { "sort" => "-id" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("id"))
    expect(handler.run).to eq([{ id: :desc }])
  end

  it "return the right hash for one ascending and one descending order for a allowed options" do
    params = { "sort" => "id,-date" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("id", "date"))
    expect(handler.run).to eq([{ id: :asc }, { date: :desc }])
  end
  it "fails if the sort key is not unique and the order is different in the duplicate" do
    params = { "sort" => "id,-id" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("id"))
    expect { handler.run }.to raise_error(ArgumentError)
  end
  it "fails if the sort key is not unique and the order is identical in the duplicate" do
    params = { "sort" => "id,id" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("id"))
    expect { handler.run }.to raise_error(ArgumentError)
  end
  it "raises an contraint error if the option is not allowed" do
    params = { "sort" => "user" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("id"))
    expect { handler.run }.to raise_error(Dry::Types::ConstraintError)
  end
  it "return an empty array when no sort options are specified" do
    params = { "sort" => "" }
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("id"))
    expect(handler.run).to eq([])
  end
  it "return an empty array if the sort param is not set" do
    params = {}
    handler = described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("id"))
    expect(handler.run).to eq([])
  end
end
