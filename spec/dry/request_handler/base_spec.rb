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
  let(:runstub) { double("Handler", run: {foo: "bar"}) }

  let(:parent) { Parent.new(request: request) }
  let(:child) { Child.new(request: request) }

  context "#filter_params" do
    it "persists the result and calls the FilterHandler only once for the same instance with a proc" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options(->(_handler, _request) { { body_user_id: 1 } })
          end
        end
      end
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::FilterHandler).to receive(:new).once.and_return(runstub)
      testobject.filter_params
      testobject.filter_params
    end
    it "does not persist the result between multiple instances with a proc" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options(->(_handler, _request) { { body_user_id: 1 } })
          end
        end
      end
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::FilterHandler).to receive(:new).twice.and_return(runstub)
      testobject1.filter_params
      testobject2.filter_params
    end
    it "persists the result and calls the FilterHandler only once for the same instance with a fixed hash" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options(body_user_id: 1)
          end
        end
      end
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::FilterHandler).to receive(:new).once.and_return(runstub)
      testobject.filter_params
      testobject.filter_params
    end
    it "does not persist the result between multiple instances with a fixed hash" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options(body_user_id: 1)
          end
        end
      end
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::FilterHandler).to receive(:new).twice.and_return(runstub)
      testobject1.filter_params
      testobject2.filter_params
    end
    it "persists the result and calls the FilterHandler only once for the same instance with nil" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options nil
          end
        end
      end
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::FilterHandler).to receive(:new).once.and_return(runstub)
      testobject.filter_params
      testobject.filter_params
    end
    it "does not persist the result between multiple instances with nil" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options nil
          end
        end
      end
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::FilterHandler).to receive(:new).twice.and_return(runstub)
      testobject1.filter_params
      testobject2.filter_params
    end
    it "passes the right arguments with a proc" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options(->(_handler, _request) { { body_user_id: 1 } })
          end
        end
      end
      expect(Dry::RequestHandler::FilterHandler)
        .to receive(:new).once.with(params:                params,
                                    schema:                "schema",
                                    additional_url_filter: "url_filter",
                                    schema_options:        { body_user_id: 1 }).and_return(runstub)
      testclass.new(request: request).filter_params
    end

    it "passes the right arguments with nil" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options nil
          end
        end
      end
      expect(Dry::RequestHandler::FilterHandler)
        .to receive(:new).with(params:                params,
                               schema:                "schema",
                               additional_url_filter: "url_filter",
                               schema_options:        {}).and_return(runstub)
      testclass.new(request: request).filter_params
    end
    it "passes the right arguments with a hash" do
      testclass = Class.new(described_class) do
        options do
          filter do
            schema "schema"
            additional_url_filter "url_filter"
            options(body_user_id: 1)
          end
        end
      end
      expect(Dry::RequestHandler::FilterHandler)
        .to receive(:new).with(params:                params,
                               schema:                "schema",
                               additional_url_filter: "url_filter",
                               schema_options:        { body_user_id: 1 }).and_return(runstub)
      testclass.new(request: request).filter_params
    end
  end
  context "#page_params" do
    testclass = Class.new(described_class) do
      options do
        page do
          default_size "default_size"
        end
      end
    end
    it "passes the right arguments" do
      expect(Dry::RequestHandler::PageHandler)
        .to receive(:new).with(params:      params,
                               page_config: { default_size: "default_size" }).and_return(runstub)
      testclass.new(request: request).page_params
    end
    it "persists the result and calls the PageHandler only once for the same instance" do
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::PageHandler)
        .to receive(:new).once.and_return(runstub)
      testobject.page_params
      testobject.page_params
    end
    it "does not persist the result between multiple instances" do
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::PageHandler)
        .to receive(:new).twice.and_return(runstub)
      testobject1.page_params
      testobject2.page_params
    end
  end
  context "#include_params" do
    testclass = Class.new(described_class) do
      options do
        include_options do
          allowed "allowed_options"
        end
      end
    end
    it "passes the right arguments" do
      expect(Dry::RequestHandler::IncludeOptionHandler)
        .to receive(:new).with(params:               params,
                               allowed_options_type: "allowed_options").and_return(runstub)
      testclass.new(request: request).include_params
    end
    it "persists the result and calls the IncludeOptionHandler only once for the same instance" do
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::IncludeOptionHandler)
        .to receive(:new).once.and_return(runstub)
      testobject.include_params
      testobject.include_params
    end
    it "does not persist the result between multiple instances" do
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::IncludeOptionHandler)
        .to receive(:new).twice.and_return(runstub)
      testobject1.include_params
      testobject2.include_params
    end
  end
  context "#sort_params" do
    testclass = Class.new(described_class) do
      options do
        sort_options do
          allowed "allowed_options"
        end
      end
    end
    it "passes the right arguments" do
      expect(Dry::RequestHandler::SortOptionHandler)
        .to receive(:new).with(params:               params,
                               allowed_options_type: "allowed_options").and_return(runstub)
      testclass.new(request: request).sort_params
    end
    it "persists the result and calls the SortOptionHandler only once for the same instance" do
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::SortOptionHandler)
        .to receive(:new).once.and_return(runstub)
      testobject.sort_params
      testobject.sort_params
    end
    it "does not persist the result between multiple instances" do
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::SortOptionHandler)
        .to receive(:new).twice.and_return(runstub)
      testobject1.sort_params
      testobject2.sort_params
    end
  end
  context "#authorization_headers" do
    testclass = Class.new(described_class) do
    end
    it "passes the right arguments" do
      expect(Dry::RequestHandler::AuthorizationHandler)
        .to receive(:new).with(env: request.env).and_return(runstub)
      testclass.new(request: request).authorization_headers
    end
    it "persists the result and calls the AuthorizationHandler only once for the same instance" do
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::AuthorizationHandler)
        .to receive(:new).once.and_return(runstub)
      testobject.authorization_headers
      testobject.authorization_headers
    end
    it "does not persist the result between multiple instances" do
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::AuthorizationHandler)
        .to receive(:new).twice.and_return(runstub)
      testobject1.authorization_headers
      testobject2.authorization_headers
    end
  end
  context "#body_params" do
    it "persists the result and calls the BodyHandler only once for the same instance with a proc" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options(->(_handler, _request) { { body_user_id: 1 } })
          end
        end
      end
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).once.and_return(runstub)
      testobject.body_params
      testobject.body_params
    end
    it "does not persist the result between multiple instances with a proc" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options(->(_handler, _request) { { body_user_id: 1 } })
          end
        end
      end
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).twice.and_return(runstub)
      testobject1.body_params
      testobject2.body_params
    end
    it "persists the result and calls the BodyHandler only once for the same instance with a fixed hash" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options(body_user_id: 1)
          end
        end
      end
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).once.and_return(runstub)
      testobject.body_params
      testobject.body_params
    end
    it "does not persist the result between multiple instances with a fixed hash" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options(body_user_id: 1)
          end
        end
      end
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).twice.and_return(runstub)
      testobject1.body_params
      testobject2.body_params
    end
    it "persists the result and calls the BodyHandler only once for the same instance with nil" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options nil
          end
        end
      end
      testobject = testclass.new(request: request)
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).once.and_return(runstub)
      testobject.body_params
      testobject.body_params
    end
    it "does not persist the result between multiple instances with nil" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options nil
          end
        end
      end
      testobject1 = testclass.new(request: request)
      testobject2 = testclass.new(request: request)
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).twice.and_return(runstub)
      testobject1.body_params
      testobject2.body_params
    end
    it "passes the right arguments with a proc as argument" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options(->(_handler, _request) { { body_user_id: 1 } })
          end
        end
      end
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).with(request:        request,
                               schema:         "schema",
                               schema_options: { body_user_id: 1 }).and_return(runstub)
      testclass.new(request: request).body_params
    end
    it "passes the right arguments with a hash as argument" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options(body_user_id: 1)
          end
        end
      end
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).with(request:        request,
                               schema:         "schema",
                               schema_options: { body_user_id: 1 }).and_return(runstub)
      testclass.new(request: request).body_params
    end
    it "passes the right arguments with nil as argument" do
      testclass = Class.new(described_class) do
        options do
          body do
            schema "schema"
            options nil
          end
        end
      end
      expect(Dry::RequestHandler::BodyHandler)
        .to receive(:new).with(request:        request,
                               schema:         "schema",
                               schema_options: {}).and_return(runstub)
      testclass.new(request: request).body_params
    end
  end
  context "#params" do
    it "tranforms the params dots to undescores before using them" do
      testclass = Class.new(described_class)
      request = instance_double("Rack::Request",
                                params: { "foo.bar" => "test",
                                          "nested"  => { "nested.foo.bar" => "test2" } },
                                env:    {},
                                body:   StringIO.new("body"))
      expect(testclass.new(request: request).send(:params)). to eq("foo_bar" => "test",
                                                                   "nested"  => { "nested_foo_bar" => "test2" })
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
