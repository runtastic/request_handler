
# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/sort_option_handler"
describe Dry::RequestHandler::SortOptionHandler do
  let(:handler) do
    described_class.new(params: params, allowed_options_type: Dry::Types["strict.string"].enum("id", "date"))
  end
  shared_examples "processes valid sort options correctly" do
    it "returns the right sort options" do
      expect(handler.run).to eq(output)
    end
  end
  shared_examples "processes invalid sort options correctly" do
    it "raises an error with invalid sort options" do
      expect { handler.run }.to raise_error(error) # TODO: Real Error
    end
  end

  # return the right hash for one ascending sort order for a allowed option
  it_behaves_like "processes valid sort options correctly" do
    let(:params) { { "sort" => "id" } }
    let(:output) { [{ id: :asc }] }
  end

  # return the right hash for one ascending sort order for a allowed option
  it_behaves_like "processes valid sort options correctly" do
    let(:params) { { "sort" => "-id" } }
    let(:output) { [{ id: :desc }] }
  end

  # return the right hash for one ascending and one descending order for a allowed options
  it_behaves_like "processes valid sort options correctly" do
    let(:params) { { "sort" => "id,-date" } }
    let(:output) { [{ id: :asc }, { date: :desc }] }
  end

  # return an empty array when no sort options are specified
  it_behaves_like "processes valid sort options correctly" do
    let(:params) { { "sort" => "" } }
    let(:output) { [] }
  end

  # return an empty array if the sort param is not set
  it_behaves_like "processes valid sort options correctly" do
    let(:params) { {} }
    let(:output) { [] }
  end

  # fails if the sort key is not unique and the order is different in the duplicate
  it_behaves_like "processes invalid sort options correctly" do
    let(:params) { { "sort" => "id,-id" } }
    let(:error) { ArgumentError }
  end

  # fails if the sort key is not unique and the order is identical in the duplicate
  it_behaves_like "processes invalid sort options correctly" do
    let(:params) { { "sort" => "id,id" } }
    let(:error) { ArgumentError }
  end

  # fails if one of the sort keys contains spaces
  it_behaves_like "processes invalid sort options correctly" do
    let(:params) { { "sort" => "id, foo" } }
    let(:error) { ArgumentError }
  end

  # raises an contraint error if the option is not allowed
  it_behaves_like "processes invalid sort options correctly" do
    let(:params) { { "sort" => "user" } }
    let(:error) { Dry::Types::ConstraintError }
  end
end
