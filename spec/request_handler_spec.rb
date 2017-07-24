# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'
class IntegrationTestRequestHandler < RequestHandler::Base
  options do
    page do
      default_size 15
      max_size 50

      posts do
        default_size 30
        max_size 50
      end

      posts__samples__photos do
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
               optional(:age__gt).filled(:int?)
               optional(:age__gte).filled(:int?)
               optional(:posts__awesome).filled(:bool?)
               optional(:posts__samples__photos__has_thumbnail).filled(:bool?)
             end)
      additional_url_filter %i[user_id]
    end

    include_options do
      allowed Dry::Types['strict.string'].enum('user', 'user__avatar', 'groups')
    end

    sort_options do
      allowed Dry::Types['strict.string'].enum('name', 'age')
    end

    fieldsets do
      allowed do
        posts Dry::Types['strict.string'].enum('awesome', 'samples')
      end
      required [:posts]
    end
  end

  def to_dto
    OpenStruct.new(
      filter:    filter_params,
      page:      page_params,
      include:   include_params,
      sort:      sort_params,
      fieldsets: fieldsets_params,
      headers:   headers
    )
  end
end

class IntegrationTestRequestHandlerWithBody < RequestHandler::Base
  options do
    body do
      schema(Dry::Validation.JSON do
               configure do
                 option :query_id
               end
               required(:id).value(eql?: query_id)
               required(:type).value(eql?: 'post')
               required(:user_id).filled(:str?)
               required(:name).filled(:str?)
               optional(:publish_on).filled(:time?)

               required(:category).schema do
                 required(:id).filled(:str?)
                 required(:type).value(eql?: 'category')
               end
             end)

      options(->(_parser, request) { { query_id: request.params['id'] } })
    end

    filter do
      schema(Dry::Validation.Form do
               configure do
                 option :body_user_id
               end
               required(:user_id).value(eql?: body_user_id)
               required(:id).filled(:str?)
             end)
      additional_url_filter %i[user_id id]
      options(->(handler, _request) { { body_user_id: handler.body_params[:user_id] } })
    end
  end

  def to_dto
    OpenStruct.new(
      body:    body_params,
      filter:  filter_params,
      headers: headers
    )
  end
end

class IntegrationTestRequestHandlerWithMultiparts < RequestHandler::Base
  options do
    multipart do
      meta do
        required true
        schema(Dry::Validation.JSON do
          configure do
            option :query_id
          end
          required(:id).value(eql?: query_id)
          required(:type).value(eql?: 'post')
          required(:user_id).filled(:str?)
          required(:name).filled(:str?)
          optional(:publish_on).filled(:time?)

          required(:category).schema do
            required(:id).filled(:str?)
            required(:type).value(eql?: 'category')
          end
        end)
        options(->(_parser, request) { { query_id: request.params['id'] } })
      end

      file do
        allowed true
      end
    end
  end

  def to_dto
    OpenStruct.new(
      multipart: multipart_params,
      headers:    headers
    )
  end
end

describe RequestHandler do
  it 'has a version' do
    expect(described_class::VERSION).not_to be_nil
  end

  before do
    RequestHandler.configure do
      separator '__'
    end
  end

  let(:headers) do
    {
      'HTTP_APP_KEY'          => 'some.app.key',
      'HTTP_USER_ID'          => '345',
      'HTTP_SOME_OTHER_STUFF' => "doesn't matter"
    }
  end
  let(:expected_headers) do
    {
      app_key:          'some.app.key',
      user_id:          '345',
      some_other_stuff: "doesn't matter"
    }
  end

  context 'w/ body' do
    it 'works' do
      raw_body = <<-JSON
      {
        "data": {
          "type": "post",
          "id": "fer342ref",
          "attributes": {
            "user_id": "awesome_user_id",
            "name": "About naming stuff and cache invalidation",
            "publish_on": "2016-09-26T12:23:55Z"
          },
          "relationships":{
            "category": {
              "data": {
                "id": "54",
                "type": "category"
              }
            }
          }
        }
      }
      JSON
      params = {
        'user_id' => 'awesome_user_id',
        'id'      => 'fer342ref'
      }

      # api call looks for example like:
      # PUT some-host.com/:user_id/posts/:id
      request = build_mock_request(params: params, headers: headers, body: raw_body)

      handler = IntegrationTestRequestHandlerWithBody.new(request: request)
      dto = handler.to_dto
      expect(dto.body).to eq(id:         'fer342ref',
                             type:       'post',
                             user_id:    'awesome_user_id',
                             name:       'About naming stuff and cache invalidation',
                             publish_on: Time.iso8601('2016-09-26T12:23:55Z'),
                             category:   {
                               id:   '54',
                               type: 'category'
                             })

      expect(dto.filter).to eq(id: 'fer342ref', user_id: 'awesome_user_id')
      expect(dto.headers).to eq(expected_headers)
    end
  end

  context 'w/o body' do
    it 'works' do
      params = {
        'user_id' => '234',
        'filter'  => {
          'name'                               => 'foo',
          'posts.awesome'                      => 'true',
          'other_param'                        => 'value',
          'age.gt'                             => '5',
          'posts.samples.photos.has_thumbnail' => 'false'
        },
        'page' => {
          'posts.size'                => '34',
          'posts.number'              => '2',
          'number'                    => '3',
          'users.size'                => '50',
          'users.number'              => '1',
          'posts.samples.photos.size' => '4'
        },
        'include' => 'user,groups,user.avatar',
        'sort'    => 'name,-age',
        'fields'  => {
          'posts' => 'samples,awesome'
        }
      }
      request = build_mock_request(params: params, headers: headers)
      allow(RequestHandler.configuration.logger).to receive(:warn)

      handler = IntegrationTestRequestHandler.new(request: request)
      dto = handler.to_dto

      expect(dto.filter).to eq(user_id:                            234,
                               name:                               'foo',
                               posts__awesome:                      true,
                               age__gt:                             5,
                               posts__samples__photos__has_thumbnail: false)

      expect(dto.page).to eq(posts__size:                  34,
                             posts__number:                2,
                             number:                      3,
                             size:                        15,
                             users__size:                  40,
                             users__number:                1,
                             posts__samples__photos__size:   4,
                             posts__samples__photos__number: 1,
                             assets__size:                 10,
                             assets__number:               1)

      expect(dto.include).to eq(%i[user groups user__avatar])

      expect(dto.sort).to eq([RequestHandler::SortOption.new('name', :asc),
                              RequestHandler::SortOption.new('age', :desc)])

      expect(dto.headers).to eq(expected_headers)
      expect(dto.fieldsets).to eq(posts: %i[samples awesome])
    end
  end

  context 'w/ multipart' do
    let(:request) do
      Rack::Request.new(env.merge(headers))
    end
    let(:env) do
      Rack::MockRequest.env_for(path, method: method, params: params, env: headers)
    end
    let(:path) { '/' }
    let(:method) { 'POST' }
    let(:params) do
      {
        'user_id' => 'awesome_user_id',
        'id' =>      'fer342ref',
        'meta' => meta_file,
        'file' => other_file
      }
    end
    let(:meta_file) do
      Rack::Multipart::UploadedFile.new("spec/fixtures/#{meta_filename}", 'application/json')
    end
    let(:meta_filename) { 'meta.json' }

    let(:other_file) do
      Rack::Multipart::UploadedFile.new('spec/fixtures/rt.png', 'image/png')
    end

    it 'works' do
      handler = IntegrationTestRequestHandlerWithMultiparts.new(request: request)
      dto = handler.to_dto

      expect(dto.multipart[:meta]).to eq(id:         'fer342ref',
                                         type:       'post',
                                         user_id:    'awesome_user_id',
                                         name:       'About naming stuff and cache invalidation',
                                         publish_on: Time.iso8601('2016-09-26T12:23:55Z'),
                                         category:   {
                                           id:   '54',
                                           type: 'category'
                                         })
      file = dto.multipart[:file]
      expect(file[:filename]).to eq('rt.png')
      expect(file[:type]).to eq('image/png')
      expect(file[:name]).to eq('file')
      expect(file[:tempfile]).not_to be_nil
      expect(file[:head]).not_to be_nil

      expect(dto.headers).to eq(expected_headers)
    end
  end
end
