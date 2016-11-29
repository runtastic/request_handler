# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/page_handler"
describe Dry::RequestHandler::PageHandler do
  shared_examples "valid input" do
    it "uses the value from the params if its within the limits" do
      handler = Dry::RequestHandler::PageHandler.new(params: params, page_config: config.lookup!("page"))
      expect(handler.run).to eq(output)
    end
  end
  shared_examples "input that causes an error" do
    it "raises an error" do
      handler = Dry::RequestHandler::PageHandler.new(params: params, page_config: config.lookup!("page"))
      expect { handler.run }.to raise_error(error)
    end
  end
  shared_examples "input that causes a warning" do
    it "prints a warning" do
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
  context "valid params and config" do
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
      it_behaves_like "valid input"
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
      it_behaves_like "valid input"
    end
  end
  context "invalid params and valid config" do
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
      it_behaves_like "valid input"
    end

    context "number is set to a non integer string" do
      let(:error) { Dry::RequestHandler::ExternalArgumentError }
      let(:params) do
        { "page" => {
          "users_size"   => "40",
          "users_number" => "asdf"
        } }
      end
      it_behaves_like "input that causes an error"
    end

    context "number is set to a negative string" do
      let(:error) { Dry::RequestHandler::ExternalArgumentError }
      let(:params) do
        { "page" => {
          "users_size"   => "40",
          "users_number" => "-20"
        } }
      end
      it_behaves_like "input that causes an error"
    end

    context "size is set to a negative string" do
      let(:error) { Dry::RequestHandler::ExternalArgumentError }
      let(:params) do
        { "page" => {
          "users_size"   => "-40",
          "users_number" => "20"
        } }
      end
      it_behaves_like "input that causes an error"
    end

    context "size is set to a non integer string" do
      let(:error) { Dry::RequestHandler::ExternalArgumentError }
      let(:params) do
        { "page" => {
          "users_size"   => "asdf",
          "users_number" => "2"
        } }
      end
      it_behaves_like "input that causes an error"
    end
  end
  context "configuration problems" do
    let(:context_config) do
      Confstruct::Configuration.new do
        page do
          default_size 15
          max_size 50
          posts do
            default_size 30
            max_size 40
          end
        end
      end
    end
    let(:params) do
      {
        "page" => {
          "size"         => "20",
          "number"       => "2",
          "posts_size"   => "500",
          "posts_number" => "2"
        }
      }
    end

    context "default_size is not an Integer" do
      let(:config) do
        context_config.page.posts.default_size = "123"
        context_config
      end
      let(:error) { Dry::RequestHandler::InternalArgumentError }
      it_behaves_like "input that causes an error"
    end

    context "max_size is not an Integer" do
      let(:config) do
        context_config.page.posts.max_size = "123"
        context_config
      end
      let(:error) { Dry::RequestHandler::InternalArgumentError }
      it_behaves_like "input that causes an error"
    end

    context "default size is not set" do
      let(:config) do
        context_config.page.posts.default_size = nil
        context_config
      end
      let(:error) { Dry::RequestHandler::NoConfigAvailableError }
      it_behaves_like "input that causes an error"
    end

    context "default size is not set on the top level" do
      let(:config) do
        context_config.page.default_size = nil
        context_config
      end
      let(:error) { Dry::RequestHandler::NoConfigAvailableError }
      it_behaves_like "input that causes an error"
    end

    context "both sizes are not set" do
      let(:config) do
        context_config.page.posts.max_size = nil
        context_config.page.posts.default_size = nil
        context_config
      end
      let(:error) { Dry::RequestHandler::NoConfigAvailableError }
      it_behaves_like "input that causes an error"
    end

    context "both sizes are not set on the top level" do
      let(:config) do
        context_config.page.max_size = nil
        context_config.page.default_size = nil
        context_config
      end
      let(:error) { Dry::RequestHandler::NoConfigAvailableError }
      it_behaves_like "input that causes an error"
    end

    context "max_size is not set" do
      let(:config) do
        context_config.page.posts.max_size = nil
        context_config
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
      it_behaves_like "input that causes a warning"
    end

    context "client sends unknown prefix" do
      let(:config) { context_config }
      let(:params) do
        {
          "page" => {
            "foo_size" => "3"
          }
        }
      end
      let(:output) do
        {
          number:       1,
          size:         15,
          posts_number: 1,
          posts_size:   30
        }
      end
      let(:warning) { "client sent unknown option [\"foo_size\"]" }
      it_behaves_like "input that causes a warning"
    end
  end

  it "raises an error if page config is set to nil" do
    expect { described_class.new(params: {}, page_config: nil) }
      .to raise_error(Dry::RequestHandler::MissingArgumentError)
  end

  it "raises an error if params is set to nil" do
    expect { described_class.new(params: nil, page_config: {}) }
      .to raise_error(Dry::RequestHandler::MissingArgumentError)
  end
end
