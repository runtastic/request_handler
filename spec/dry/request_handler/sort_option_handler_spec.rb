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
      expect { handler.run }.to raise_error(error)
    end
  end

  context "one ascending sort order for an allowed option" do
    let(:params) { { "sort" => "id" } }
    let(:output) { [Dry::RequestHandler::SortOption.new("id", :asc)] }
    it_behaves_like "processes valid sort options correctly"
  end

  context "one ascending sort order for an allowed option" do
    let(:params) { { "sort" => "-id" } }
    let(:output) { [Dry::RequestHandler::SortOption.new("id", :desc)] }
    it_behaves_like "processes valid sort options correctly"
  end

  context "one ascending and one descending order for allowed options" do
    let(:params) { { "sort" => "id,-date" } }
    let(:output) do
      [Dry::RequestHandler::SortOption.new("id", :asc),
       Dry::RequestHandler::SortOption.new("date", :desc)]
    end
    it_behaves_like "processes valid sort options correctly"
  end

  context "no sort options are specified" do
    let(:params) { { "sort" => "" } }
    let(:output) { [] }
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    it_behaves_like "processes invalid sort options correctly"
  end

  context "sort param is not set" do
    let(:params) { {} }
    let(:output) { [] }
    it_behaves_like "processes valid sort options correctly"
  end

  context "sort key is not unique and the order is different in the duplicate" do
    let(:params) { { "sort" => "id,-id" } }
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    it_behaves_like "processes invalid sort options correctly"
  end

  context "sort key is not unique and the order is identical in the duplicate" do
    let(:params) { { "sort" => "id,id" } }
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    it_behaves_like "processes invalid sort options correctly"
  end

  context "one of the sort keys contains spaces" do
    let(:params) { { "sort" => "id, foo" } }
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    it_behaves_like "processes invalid sort options correctly"
  end

  context "option is not allowed" do
    let(:params) { { "sort" => "user" } }
    let(:error) { Dry::RequestHandler::OptionNotAllowedError }
    it_behaves_like "processes invalid sort options correctly"
  end
end
