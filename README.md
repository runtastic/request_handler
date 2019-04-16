# RequestHandler

[![Gem Version](https://badge.fury.io/rb/request_handler.svg)](https://badge.fury.io/rb/request_handler)
[![Build Status](https://travis-ci.org/runtastic/request_handler.svg?branch=master)](https://travis-ci.org/runtastic/request_handler)
[![codecov](https://codecov.io/gh/runtastic/request_handler/branch/master/graph/badge.svg)](https://codecov.io/gh/runtastic/request_handler)

This gem allows easy and dry handling of requests based on the dry-validation
gem for validation and data coersion. It allows to handle headers, filters,
include_options, sorting and of course to validate the body.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'request_handler'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install request_handler

## Configuration

The default logger and separator can be changed globally:

```ruby
RequestHandler.configure do
  logger Logger.new(STDERR)
  separator '____'
  validation_engine RequestHandler::Validation::DryEngine
end
```

JSON:API-style error data can be included in validation errors raised by `RequestHandler`.

```ruby
RequestHandler.configure do
  raise_jsonapi_errors = true # default: false
end
```


### Validation Engine
Per default this gem uses the `DryEngine` which relies on dry-validation. All
examples in this Readme assume you are using this default engine. However
you can also use the builtin `DefinitionEngine`, which uses [Definition](https://github.com/Goltergaul/definition) as validation library:

```ruby
RequestHandler.configure do
  require 'request_handler/validation/definition_engine'
  validation_engine RequestHandler::Validation::DefinitionEngine
end
```

You can also implement your own engine to use any other library, by implementing
the abstract class `RequestHandler::Validation::Engine`

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

Generic query params can be added by using the `query` block. This may be useful
if parameters should be validated which cannot be assigned to other predefined
option blocks.

A `type` param can be passed in the `body` block, or the `resource` block in
[multipart requests](#multipart-requests) (like `question` in the example below).
You can pass either a symbol or a string.
At the moment there are only "jsonapi" and "json" available for `type`. This
defines if the JsonApiDocumentParser or JsonParser is used.
If nothing is defined, JsonApiDocumentParser will be used by default.

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
        Dry::Validation.Params do
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

    query do
      schema(
        Dry::Validation.Params do
          optional(:name).filled(:str?)
        end
      )
    end

    body do
      type :jsonapi
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

### Multipart requests
It is also possible to process and validate multipart requests, consisting of an arbitrary number of parts.
You can require specific resources, all the other listed resources are optional

The following request handler requires a question (which will be uploaded as a json-file) and accepts an additional
file related to the question

```ruby
class CreateQuestionHandler < RequestHandler::Base
  options do
    multipart do
      question do
        required true
        type "json"
        schema(
          Dry::Validation.JSON do
            required(:id).filled(:str?)
            required(:type).filled(:str?)
            required(:content).filled(:str?)
          end
        )
      end

      file do
        # no validation necessary
      end
    end
  end

  def to_dto
    # see the resulting multipart_params below
    { multipart: multipart_params }
  end
end
```

Assuming that the request consists of a json file `question.json` containing  
``` json
{
  "id": "1",
  "type": "questions",
  "content": "How much is the fish?"
}
```

and an additional file `image.png`, the resulting `multipart_params` will be the following:

``` ruby
{
  question:
    {
      id:      '1',
      type:    'questions',
      content: 'How much is the fish?'
    },
  file:
    {
      filename: 'image.png',
      type:     'application/octet-stream'
      name:     'file',
      tempfile: #<Tempfile:/...>,
      head:     'Content-Disposition: form-data;...'
    }
}
```

Please note that each part's content has to be uploaded as a separate file currently.

### JSON:API errors

Errors caused by bad requests respond to `:errors`.

When the gem is configured to `raise_jsonapi_errors`, this method returns a list of hashes
containing `code`, `status`, `detail`, (`links`) and `source` for each specific issue
that contributed to the error. Otherwise it returns an empty array.

The exception message contains `<error code>: <source> <detail>` for every issue,
with one issue per line.

| `:code`                   | `:status` | What is it? |
|:--------------------------|:----------|:------------|
| INVALID_RESOURCE_SCHEMA   | 422       | Resource did not pass configured validation |
| INVALID_QUERY_PARAMETER   | 400       | Query parameter violates syntax or did not pass configured validation |
| MISSING_QUERY_PARAMETER   | 400       | Query parameter required in configuration is missing |
| INVALID_JSON_API          | 400       | Request body violates JSON:API syntax |
| INVALID_MULTIPART_REQUEST | 400       | Sidecar resource missing or invalid JSON |

#### Example
```ruby
rescue RequestHandler::SchemaValidationError => e
  puts e.errors
end
```

```ruby
[
  {
    status: '422',
    code: 'INVALID_RESOURCE_SCHEMA',
    title: 'Invalid resource',
    detail: 'is missing',
    source: { pointer: '/data/attributes/name' }
  }
]
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

After checking out the repo, run `bin/setup` to install dependencies. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

Run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push git
commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/runtastic/request_handler.
This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [code of conduct][cc].

## License
The gem is available as open source under [the terms of the MIT License][mit].

[mit]: https://choosealicense.com/licenses/mit/
[cc]: ../CODE_OF_CONDUCT.md
