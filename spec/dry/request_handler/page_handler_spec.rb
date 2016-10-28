# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/page_handler"
describe Dry::RequestHandler::PageHandler do
  shared_examples "uses the right values for page and size" do
    it "uses the value from the params if its within the limits" do
      handler = Dry::RequestHandler::PageHandler.new(params: params, page_config: config.lookup!("page"))
      expect(handler.run).to eq(output)
    end
  end
  shared_examples "handles invalid inputs correctly" do
    it "raises the an Dry::RequestHandler::InvalidArgumentError for an invalid input" do
      handler = Dry::RequestHandler::PageHandler.new(params: params, page_config: config.lookup!("page"))
      expect { handler.run }.to raise_error(error)
    end
  end
  shared_examples "handles missing options correctly" do
    it "prints a warning for a missing option" do
      handler = Dry::RequestHandler::PageHandler.new(params: params, page_config: config.lookup!("page"))
      expect(Dry::RequestHandler.configuration.logger).to receive(:warn).with(warning)
      expect(handler.run).to eq(output)
    end
  end

  let(:config) do
    Confstruct::Configuration.new do
      page do
        default_size 15
        max_size 50

        posts do
          default_size 30
          max_size 50
        end

        users do
          default_size 20
          max_size 40
        end
      end
    end
  end

  context "size from the params is below the limit" do
    let(:params) do
      {
        "page" => {
          "posts_size"   => "34",
          "posts_number" => "2",
          "users_size"   => "25",
          "users_number" => "2"
        }
      }
    end
    let(:output) do
      {
        number:       1,
        size:         15,
        posts_number: 2,
        posts_size:   34,
        users_number: 2,
        users_size:   25
      }
    end
    it_behaves_like "uses the right values for page and size"
  end

  context "param requests a size bigger than allowed" do
    let(:params) do
      {
        "page" => {
          "posts_size"   => "34",
          "posts_number" => "2",
          "users_size"   => "100",
          "users_number" => "2"
        }
      }
    end
    let(:output) do
      {
        number:       1,
        size:         15,
        posts_number: 2,
        posts_size:   34,
        users_number: 2,
        users_size:   40
      }
    end
    it_behaves_like "uses the right values for page and size"
  end

  context "size not defined in the params" do
    let(:params) do
      { "page" => {
        "users_size"   => "39",
        "users_number" => "2"
      } }
    end
    let(:output) do
      { number:       1,
        size:         15,
        posts_number: 1,
        posts_size:   30,
        users_number: 2,
        users_size:   39 }
    end
    it_behaves_like "uses the right values for page and size"
  end

  context "number is set to a non integer string" do
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    let(:params) do
      { "page" => {
        "users_size"   => "40",
        "users_number" => "asdf"
      } }
    end
    it_behaves_like "handles invalid inputs correctly"
  end

  context "number is set to a negative string" do
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    let(:params) do
      { "page" => {
        "users_size"   => "40",
        "users_number" => "-20"
      } }
    end
    it_behaves_like "handles invalid inputs correctly"
  end

  context "size is set to a negative string" do
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    let(:params) do
      { "page" => {
        "users_size"   => "-40",
        "users_number" => "20"
      } }
    end
    it_behaves_like "handles invalid inputs correctly"
  end

  context "size is set to a non integer string" do
    let(:error) { Dry::RequestHandler::ExternalArgumentError }
    let(:params) do
      { "page" => {
        "users_size"   => "asdf",
        "users_number" => "2"
      } }
    end
    it_behaves_like "handles invalid inputs correctly"
  end

  it "raises an error if page config is set to nil" do
    expect { described_class.new(params: {}, page_config: nil) }
      .to raise_error(Dry::RequestHandler::MissingArgumentError)
  end

  it "raises an error if params is set to nil" do
    expect { described_class.new(params: nil, page_config: {}) }
      .to raise_error(Dry::RequestHandler::MissingArgumentError)
  end

  context "config with missing options" do
    let(:config) do
      Confstruct::Configuration.new do
        page do
          default_size 15
          max_size 50

          posts do
            default_size 30
          end
          comments do
          end
        end
      end
    end

    context "params contain config options that are not set on the server" do
      let(:params) do
        {
          "page" => {
            "posts_size"      => "34",
            "posts_number"    => "2",
            "comments_size"   => "200",
            "comments_number" => "10"
          }
        }
      end
      let(:output) do
        {
          number:          1,
          size:            15,
          posts_number:    2,
          posts_size:      34,
          comments_size:   200,
          comments_number: 10
        }
      end
      it_behaves_like "uses the right values for page and size"
    end

    it "raises an error if there is no way to determine the size of an option" do
      params = {
        "page" => {
          "posts_size"   => "34",
          "posts_number" => "2"
        }
      }
      handler = Dry::RequestHandler::PageHandler.new(params: params, page_config: config.lookup!("page"))
      expect { handler.run }.to raise_error(Dry::RequestHandler::NoConfigAvailableError)
    end

    it "prints warnings if both sized are not set" do
      params = {
        "page" => {
          "comments_size"   => "500",
          "comments_number" => "2"
        }
      }
      handler = Dry::RequestHandler::PageHandler.new(params: params, page_config: config.lookup!("page"))
      expect(Dry::RequestHandler.configuration.logger).to receive(:warn).twice
      handler.run
    end
  end

  context "max size is not set" do
    let(:config) do
      Confstruct::Configuration.new do
        page do
          default_size 15
          max_size 50
          posts do
            default_size 30
          end
        end
      end
    end
    let(:params) do
      {
        "page" => {
          "posts_size"   => "500",
          "posts_number" => "2"
        }
      }
    end
    let(:output) do
      {
        number:       1,
        size:         15,
        posts_number: 2,
        posts_size:   500
      }
    end
    let(:warning) { "posts max_size config not set" }
    it_behaves_like "handles missing options correctly"
  end

  context "default size is not set" do
    let(:config) do
      Confstruct::Configuration.new do
        page do
          default_size 15
          max_size 50
          posts do
            max_size 30
          end
        end
      end
    end
    let(:params) do
      {
        "page" => {
          "posts_size"   => "500",
          "posts_number" => "2"
        }
      }
    end
    let(:output) do
      {
        number:       1,
        size:         15,
        posts_number: 2,
        posts_size:   30
      }
    end
    let(:warning) { "posts default_size config not set" }
    it_behaves_like "handles missing options correctly"
  end

  context "default and max size are not set" do
    let(:config) do
      Confstruct::Configuration.new do
        page do
          default_size 15
          max_size 50
        end
      end
    end
    let(:params) do
      {
        "page" => {
          "foo_size" => "3"
        }
      }
    end
    let(:output) do
      {
        number: 1,
        size:   15
      }
    end
    let(:warning) { "client sent unknown option [\"foo_size\"]" }
    it_behaves_like "handles missing options correctly"
  end
end
