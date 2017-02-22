# RequestHandler

[![Gem Version](https://badge.fury.io/rb/request_handler.svg)](https://badge.fury.io/rb/request_handler)
[![Build Status](https://travis-ci.org/runtastic/request_handler.svg?branch=master)](https://travis-ci.org/runtastic/request_handler)
[![codecov](https://codecov.io/gh/runtastic/request_handler/branch/master/graph/badge.svg)](https://codecov.io/gh/runtastic/request_handler)

This gem allows easy and dry handling of requests based on the dry-validation
gem for validation and data coersion. It allows to handle headers, filters,
include_options, sorting and of course to validate the body.

## ToDo

- update documentation
- identify missing features compared to [jsonapi](https://jsonapi.org)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'request_handler'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install request_handler

## Usage

To set up a handler, you need create a class which inherits from
`RequestHandler::Base`, providing at least the options block and a `to_dto`
method with the parts you want to use. To use it, create a new instance of the
handler passing in the request, after that you can use the handler.dto method to
process and access the data. Here is a short example, check
`spec/integration/request_handler_spec.rb` for a detailed one.

Please note that pagination only considers options that are configured on the
server (at least an empty configuration block int the page block), other options
sent by the client are ignored and will cause a warning.

```ruby
require "dry-validation"
require "request_handler"
class DemoHandler < RequestHandler::Base
  options do
    page do
      default_size 10
      max_size 20
      comments do
        default_size 20
        max_size 100
      end
    end

    include_options do
      allowed Dry::Types["strict.string"].enum("comments", "author")
    end

    sort_options do
      allowed Dry::Types["strict.string"].enum("age", "name")
    end

    filter do
      schema(
        Dry::Validation.Form do
          configure do
            option :foo
          end
          required(:name).filled(:str?)
        end
      )
      additional_url_filter %i(user_id id)
      options(->(_handler, _request) { { foo: "bar" } })
      # options({foo: "bar"}) # also works for hash options instead of procs
    end

    body do
      schema(
        Dry::Validation.JSON do
          configure do
            option :foo
          end
          required(:id).filled(:str?)
        end
      )
      options(->(_handler, _request) { { foo: "bar" } })
      # options({foo: "bar"}) # also works for hash options instead of procs
    end
  end

  def to_dto
    OpenStruct.new(
      body:    body_params,
      page:    page_params,
      include: include_params,
      filter:  filter_params,
      sort:    sort_params,
      headers: headers
    )
  end
end

# Given a Rack::Request you can create a well defined dto through the request handler:
DemoHandler.new(request: request).to_dto
```
### Nested Attributes

For nested attributes all options or parameter will be flattened and nesting
will be represented by joining the nesting levels with the defined separator
string. By default this will be double underscore `__`.

This means in the request handler options one must use the attributes as flat
structure with the configured separator.

#### Example

Input query parameters like the following:

```http
GET /users?filter[name]=John&filter[posts.tag]=health
```

will be parsed as

```ruby
{
  name: "John",
  posts__tag: "health"
}
```

Same is applied for sort and include options.

```http
GET /users?sort=posts.published_on&include=posts.comments
```

becomes

```ruby
include_options = [:posts__comments]
sort_options = SortOption.new(:posts__published_on, :asc)
```

### Included relations

Sometimes you want to create a single resource with its relations in a single
request, ensuring that everything or nothing at all is created.  However, the
current JSON API specification does not mention anything about how to achieve
this at all, it is expected that all associated resources already exist.  
`request_handler` attempts to solve this problem by allowing the request body
to contain an `included` array with all the resources that have to be created.

#### Example

With this request handler:

```ruby
class CreateQuestionHandler < RequestHandler::Base
  options do
    body do
      schema(
        Dry::Validation.JSON do
          required(:id).filled(:str?)
          required(:type).filled(:str?)
          required(:content).filled(:str?)

          optional(:media).schema do
            required(:id).filled(:str?)
            required(:type).filled(:str?)
          end
        end
      )

      included do
        media(
          Dry::Validation.JSON do
            required(:id).filled(:str?)
            required(:type).filled(:str?)
            required(:url).filled(:str?)

            optional(:categories).schema do
              required(:id).filled(:str?)
              required(:type).filled(:str?)
            end
          end
        )
      end
    end
  end

  def to_dto
    # see the resulting body_params below
    { body: body_params }
  end
end
```

The following JSON object including its included items is validated with the
defined schema:

``` json
{
  "data": {
    "id": "1",
    "type": "questions",
    "attributes": {
      "content": "How much is the fish?"
    },
    "relationships": {
      "media": {
          "data": {
            "id": "image-123456",
            "type": "media"
          }
        }
      }
    }
  },
  "included": [
    {
      "id": "image-123456",
      "type": "media",
      "attributes": {
        "url": "https://example.com/fish.jpg"
      },
      "relationships": {
        "categories": {
          "data": {
            "id": "123",
            "type": "categories"
          }
        }
      }
    }
  ]
}
```

The resulting `body_params` will be this:

``` ruby
[
  # The first object is the main resource object, i.e. the one that is about to
  # be created
  {
    id:      '1',
    type:    'questions',
    content: 'How much is the fish?'
    media:   [
      {
        id:   'image-123456',
        type: 'media'
      }
    ]
  },
  # The remaining objects are every included object, validated with the schema
  # defined above
  {
    id:         'image-123456',
    type:       'media',
    url:        'https://example.com/fish.jpg',
    categories: {
      id:   '123',
      type: 'categories'
    }
  }
]
```

### Configuration

The default logger and separator can be changed globally by using
`RequestHandler.configure {}`.

```ruby
RequestHandler.configure do
  logger Logger.new(STDERR)
  separator '____'
end
```

### Caveats

It is currently expected that _url_ parameter are already parsed and included in
the request params. With Sinatra requests the following is needed to accomplish
this:

```ruby
get "/users/:user_id/posts" do
  request.params.merge!(params)
  dto = DemoHandler.new(request: request).to_dto
  # more code
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

## Contributing
Bug reports and pull requests are welcome on GitHub at
https://github.com/runtastic/request_handler. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of
the [MIT License](http://opensource.org/licenses/MIT).
