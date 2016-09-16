# frozen_string_literal: true
require "spec_helper"
require "ostruct"

class IntegrationTestRequestHandler < Dry::RequestHandler::Base
  options do
    page do
      default_size 15
      max_size 50

      posts do
        default_size 30
        max_size 50
      end

      posts_samples_photos do
        default_size 3
      end

      users do
        default_size 20
        max_size 40
      end

      assets do
        default_size 10
        max_size 15
      end
    end

    filter do
      schema(Dry::Validation.Form do
        required(:user_id).filled(:int?)
        required(:name).filled(:str?)
        optional(:age_gt).filled(:int?)
        optional(:age_gte).filled(:int?)
        optional(:posts_awesome).filled(:bool?)
        optional(:posts_samples_photos_has_thumbnail).filled(:bool?)
      end)
      additional_url_filter %i(user_id)
    end

    include_options do
      allowed Dry::Types["strict.string"].enum("user", "user.avatar", "groups")
    end

    sort_options do
      allowed Dry::Types["strict.string"].enum("name", "age")
    end
  end

  def to_dto
    OpenStruct.new(
      filter:  filter_params,
      page:    page_params,
      include: include_params,
      sort:    sort_params,
      header:  authorization_headers
    )
  end
end

class IntegrationTestRequestHandlerWithBody < Dry::RequestHandler::Base
  options do
    body do
      schema(Dry::Validation.Form do
        required(:user_id).filled(:int?)
        required(:name).filled(:str?)
        optional(:age_gt).filled(:int?)
        optional(:age_gte).filled(:int?)
      end)
    end
  end
  def to_dto
    body_params
  end
end

describe Dry::RequestHandler do
  it "has a version" do
    expect(described_class::VERSION).not_to be_nil
  end

  it do
    params = {
      "user_id" => "234",
      "filter"  => { "name" => "foo", "posts.awesome" => "true", "other_param" => "value", "age.gt" => "5", "posts.samples.photos.has_thumbnail" => "false" },
      "page"    => { "posts.size" => "34", "posts.number" => "2", "number" => "3", "users.size" => "50", "users.number" => "1", "posts.samples.photos.size" => "4" },
      "include" => "user,groups",
      "sort"    => "name,-age"
    }
    headers = {
      "HTTP_AUTH"  => "some.app.key",
      "ACCEPT"  => "345",
      "HTTP_SOME_OTHER_STUFF" => "doesn't matter"
    }
    request = instance_double("Rack::Request", params: params, env: headers)

    handler = IntegrationTestRequestHandler.new(request: request)
    dto = handler.to_dto
    expect(dto.filter).to eq(user_id: 234, name: "foo", posts_awesome: true, age_gt: 5, posts_samples_photos_has_thumbnail: false)
    expect(dto.page).to eq(posts_size: 34, posts_number: 2, number: 3, size: 15, users_size: 40, users_number: 1, posts_samples_photos_size: 4, posts_samples_photos_number: 1, assets_size: 10, assets_number: 1)
    expect(dto.include).to eq(%i(user groups))
    expect(dto.sort).to eq([{ name: :asc }, { age: :desc }])
    expect(dto.header).to eq(auth: "some.app.key", accept: "345")
  end

  it "with body" do
    raw_body = ""
    request = instance_double("Rack::Request", params: {}, env: {}, body)

    handler = IntegrationTestRequestHandlerWithBody.new(request: request)
    dto = handler.to_dto
  end
end
