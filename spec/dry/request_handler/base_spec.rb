# frozen_string_literal: true
require "spec_helper"
require "dry/request_handler/base"

class Parent < Dry::RequestHandler::Base
  options do
    option_0_o "parent_0_o"
    option_0_n "parent_0_n"
    option_1 do
      option_1_o "parent_1_o"
      option_1_n "parent_1_n"
      option_2 do
        option_2_o "parent_2_o"
        option_2_n "parent_2_n"
      end
    end
  end
end
class Child < Parent
  options do
    option_0_o "child_0_o"
    option_0_c "child_0_c"
    option_1 do
      option_1_o "child_1_o"
      option_1_c "child_1_c"
      option_2 do
        option_2_o "child_2_o"
        option_2_c "child_2_c"
      end
    end
  end
end

shared_examples "correct_arguments_passed" do
  it "passes the right arguments to the handler" do
    expect(tested_handler).to receive(:new).with(expected_args).and_return(runstub)
    testclass.new(request: request).send(tested_method)
  end
end
shared_examples "correct_persistence" do
  let(:n) { 2 }

  it "persists for the same instance" do
    instance = testclass.new(request: request)
    expect(tested_handler).to receive(:new).once.and_return(runstub)
    n.times { instance.send(tested_method) }
  end

  it "does not persist for different instances" do
    instances = []
    n.times { instances << testclass.new(request: request) }
    expect(tested_handler).to receive(:new).exactly(n).times.and_return(runstub)
    instances.each { |instance| instance.send(tested_method) }
  end
end

describe Dry::RequestHandler::Base do
  let(:params) do
    {
      "url_filter" => "bar"
    }
  end
  let(:request) do
    instance_double("Rack::Request",
                    params: params,
                    env:    {},
                    body:   StringIO.new("body"))
  end
  let(:runstub) { double("Handler", run: { foo: "bar" }) }

  let(:parent) { Parent.new(request: request) }
  let(:child) { Child.new(request: request) }
  context "#filter_params" do
    let(:testclass) do
      opts = tested_options[:input]
      Class.new(Dry::RequestHandler::Base) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options(opts)
          end
        end
      end
    end
    let(:expected_args) do
      {
        params:                params,
        schema:                "schema",
        additional_url_filter: "url_filter",
        schema_options:        tested_options[:output]
      }
    end
    let(:tested_method)  { :filter_params }
    let(:tested_handler) { Dry::RequestHandler::FilterHandler }

    context "with a proc as options" do
      let(:tested_options) { { input: ->(_handler, _request) { { body_user_id: 1 } }, output: { body_user_id: 1 } } }
      it_behaves_like "correct_persistence"
      it_behaves_like "correct_arguments_passed"
    end

    context "with a hash options" do
      let(:tested_options) { { input: { foo: "bar" }, output: { foo: "bar" } } }
      it_behaves_like "correct_persistence"
      it_behaves_like "correct_arguments_passed"
    end

    context "with nil as options" do
      let(:tested_options) { { input: nil, output: {} } }
      it_behaves_like "correct_persistence"
      it_behaves_like "correct_arguments_passed"
    end
  end

  context "#page_params" do
    let(:testclass) do
      Class.new(Dry::RequestHandler::Base) do
        options do
          page do
            default_size "default_size"
          end
        end
      end
    end
    let(:expected_args) do
      {
        params:      params,
        page_config: { default_size: "default_size" }
      }
    end
    let(:tested_method)  { :page_params }
    let(:tested_handler) { Dry::RequestHandler::PageHandler }
    it_behaves_like "correct_persistence"
    it_behaves_like "correct_arguments_passed"
  end

  context "#include_params" do
    let(:testclass) do
      Class.new(Dry::RequestHandler::Base) do
        options do
          include_options do
            allowed "allowed_options"
          end
        end
      end
    end
    let(:expected_args) do
      {
        params:               params,
        allowed_options_type: "allowed_options"
      }
    end
    let(:tested_method)  { :include_params }
    let(:tested_handler) { Dry::RequestHandler::IncludeOptionHandler }
    it_behaves_like "correct_persistence"
    it_behaves_like "correct_arguments_passed"
  end

  context "#sort_params" do
    let(:testclass) do
      Class.new(Dry::RequestHandler::Base) do
        options do
          sort_options do
            allowed "allowed_options"
          end
        end
      end
    end
    let(:expected_args) do
      {
        params:               params,
        allowed_options_type: "allowed_options"
      }
    end
    let(:tested_method)  { :sort_params }
    let(:tested_handler) { Dry::RequestHandler::SortOptionHandler }
    it_behaves_like "correct_persistence"
    it_behaves_like "correct_arguments_passed"
  end

  context "#authorization_headers" do
    let(:testclass) do
      Class.new(Dry::RequestHandler::Base) do
        options do
          sort_options do
            allowed "allowed_options"
          end
        end
      end
    end
    let(:expected_args) do
      {
        env: request.env
      }
    end
    let(:tested_method)  { :authorization_headers }
    let(:tested_handler) { Dry::RequestHandler::AuthorizationHandler }
    it_behaves_like "correct_persistence"
    it_behaves_like "correct_arguments_passed"
  end

  context "#body_params" do
    # TODO: find a way to use the test_options inside the new class to save unneccessary code duplication
    let(:testclass) do
      opts = tested_options[:input]
      Class.new(Dry::RequestHandler::Base) do
        options do
          body do
            schema "schema"
            options(opts)
          end
        end
      end
    end
    let(:expected_args) do
      {
        request:        request,
        schema:         "schema",
        schema_options: tested_options[:output]
      }
    end
    let(:tested_method)  { :body_params }
    let(:tested_handler) { Dry::RequestHandler::BodyHandler }

    context "with a proc as options" do
      let(:tested_options) { { input: ->(_handler, _request) { { body_user_id: 1 } }, output: { body_user_id: 1 } } }
      it_behaves_like "correct_persistence"
      it_behaves_like "correct_arguments_passed"
    end

    context "with a hash as options" do
      let(:tested_options) { { input: { body_user_id: 1 }, output: { body_user_id: 1 } } }
      it_behaves_like "correct_persistence"
      it_behaves_like "correct_arguments_passed"
    end

    context "with nil as options" do
      let(:tested_options) { { input: nil, output: {} } }
      it_behaves_like "correct_persistence"
      it_behaves_like "correct_arguments_passed"
    end
  end
  context "#params" do
    it "tranforms the params dots to undescores before using them" do
      testclass = Class.new(described_class)
      request = instance_double("Rack::Request",
                                params:
                                        {
                                          "foo.bar"      => "test",
                                          "nested"       => { "nested.foo.bar" => "test2" },
                                          "nested.twice" => { "nested.twice.foo.bar" =>{ "nested.again" => "test3" } }
                                        },
                                env:    {},
                                body:   StringIO.new("body"))
      expect(testclass.new(request: request).send(:params))
        .to eq("foo_bar"      => "test",
               "nested"       => { "nested_foo_bar" => "test2" },
               "nested_twice" => { "nested_twice_foo_bar" =>{ "nested_again" => "test3" } })
    end
  end
  context "the parentclass" do
    it "still has the correct not nested attribute after being inherited" do
      expect(parent.send(:config).lookup!("option_0_o")).to eq("parent_0_o")
    end
    it "still has the correct not nested attribute that is not overwritten after being inherited" do
      expect(parent.send(:config).lookup!("option_0_n")).to eq("parent_0_n")
    end
    it "does not have the not nested attribute that was introduced in the child" do
      expect(parent.send(:config).lookup!("option_0_c")).to eq(nil)
    end

    it "still has the correct nested attribute after being inherited" do
      expect(parent.send(:config).lookup!("option_1.option_1_o")).to eq("parent_1_o")
    end
    it "still has the correct nested attribute that is not overwritten after being inherited" do
      expect(parent.send(:config).lookup!("option_1.option_1_n")).to eq("parent_1_n")
    end
    it "does not have the nested attribute that was introduced in the child" do
      expect(parent.send(:config).lookup!("option_1.option_1_c")).to eq(nil)
    end

    it "still has the correct double nested attribute after being inherited" do
      expect(parent.send(:config).lookup!("option_1.option_2.option_2_o")).to eq("parent_2_o")
    end
    it "still has the correct double nested attribute that is not overwritten after being inherited" do
      expect(parent.send(:config).lookup!("option_1.option_2.option_2_n")).to eq("parent_2_n")
    end
    it "does not have the double nested attribute that was introduced in the child" do
      expect(parent.send(:config).lookup!("option_1.option_2.option_2_c")).to eq(nil)
    end
  end
  context "the childclass" do
    it "overwrites the not nested attribute correctly" do
      expect(child.send(:config).lookup!("option_0_o")).to eq("child_0_o")
    end
    it "doesn't overwrite the not nested attribute that it shoudn't" do
      expect(child.send(:config).lookup!("option_0_n")).to eq("parent_0_n")
    end
    it "has the not nested attribute that was introduced by the child" do
      expect(child.send(:config).lookup!("option_0_c")).to eq("child_0_c")
    end

    it "overwrites the nested attribute correctly" do
      expect(child.send(:config).lookup!("option_1.option_1_o")).to eq("child_1_o")
    end
    it "doesn't overwrite the nested attribute that it shoudn't" do
      expect(child.send(:config).lookup!("option_1.option_1_n")).to eq("parent_1_n")
    end
    it "has the nested attribute that was introduced by the child" do
      expect(child.send(:config).lookup!("option_1.option_1_c")).to eq("child_1_c")
    end

    it "overwrites the double nested attribute correctly" do
      expect(child.send(:config).lookup!("option_1.option_2.option_2_o")).to eq("child_2_o")
    end
    it "doesn't overwrite the double nested attribute that it shoudn't" do
      expect(child.send(:config).lookup!("option_1.option_2.option_2_n")).to eq("parent_2_n")
    end
    it "has the double nested attribute that was introduced by the child" do
      expect(child.send(:config).lookup!("option_1.option_2.option_2_c")).to eq("child_2_c")
    end
  end
end
