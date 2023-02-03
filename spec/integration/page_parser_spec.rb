# frozen_string_literal: true

require "spec_helper"

describe RequestHandler do
  shared_examples "it validates page" do
    subject(:to_dto) { testclass.new(request: request).to_dto }

    let(:request) { build_mock_request(params: params, headers: {}, body: "") }
    context "PageParser" do
      context "invalid settings" do
        let(:testclass) do
          Class.new(RequestHandler::Base) do
            options do
              page do
                max_size "foo"
                default_size "bar"
              end
            end
            def to_dto
              OpenStruct.new(
                page: page_params
              )
            end
          end
        end

        context "without page params" do
          let(:params) { {} }

          it { expect { to_dto }.to raise_error(RequestHandler::InternalArgumentError) }
        end
      end

      context "valid settings" do
        let(:testclass) do
          Class.new(RequestHandler::Base) do
            options do
              page do
                max_size 100
                default_size 50
              end
            end
            def to_dto
              OpenStruct.new(
                page:  page_params
              )
            end
          end
        end

        context "with no params" do
          let(:params) { nil }

          it { expect { to_dto }.to raise_error(RequestHandler::MissingArgumentError) }
        end

        context "with valid data and valid options" do
          let(:params) { { "page" => { "size" => "500", "number" => "2" } } }

          it { expect(to_dto).to eq(OpenStruct.new(page: { number: 2, size: 100 })) }
        end
      end

      context "valid settings with missing parts" do
        let(:testclass) do
          Class.new(RequestHandler::Base) do
            options do
              page do
              end
            end
            def to_dto
              OpenStruct.new(
                page:  page_params
              )
            end
          end
        end

        context "with no page params given" do
          let(:params) { {} }

          it { expect { to_dto }.to raise_error(RequestHandler::NoConfigAvailableError) }
        end
      end
    end
  end

  context "with dry engine" do
    include_context "with dry validation engine" do
      it_behaves_like "it validates page"
    end
  end

  context "with definition engine" do
    include_context "with definition validation engine" do
      it_behaves_like "it validates page"
    end
  end
end
