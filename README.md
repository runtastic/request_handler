# Dry::RequestHandler

This gem allows easy and dry handling of requests based on the dry-validation gem, which is a replacement for virtus. It allows to handle authorization, filters, include_options, sorting and of course to validate the body.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dry-request_handler', source: "http://gems.example.com"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dry-request_handler --source "http://gems.example.com"

## Usage

To set up a handler, you need to extend the `Dry::RequestHandler::Base class`, providing at least the options block and a to_dto method with the parts you want to use.
To use it, create a new instance of the handler passing in the request, after that you can use the handler.dto method to process and access the data.
Here is a short example, check `spec/dry/request_handler_spec.rb` for a detailed one.
```ruby
require "dry-validation"
require "dry/request_handler/base"
class DemoHandler < Dry::RequestHandler::Base
  options do
    # pagination settings
    page do
      default_size 10
      max_size 20
      comments do
        default_size 20
        max_size 100
      end
    end
    # access with handler.page_params

    # include options
    include_options do
      allowed Dry::Types["strict.string"].enum("comments", "author")
    end
    # access with handler.include_params

    # sort options
    sort_options do
      allowed Dry::Types["strict.string"].enum("age", "name")
    end
    # access with handler.sort_params

    # filters
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
    # access with handler.filter_params

    # body
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
    # access via handler.body_params

    # also available: handler.authorization_headers

    def to_dto
      OpenStruct.new(
        body:    body_params,
        page:    page_params,
        include: include_params,
        filter:  filter_params,
        sort:    sort_params,
        headers: authorization_headers
      )
    end
  end
end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake inabox:release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [gems.example.com](http://gems.example.com).

## Contributing

Bug reports and requests are welcome on [jira](https://issues.example.com/projects/RBGEM/issues) with component `dry-request_handler`
Pull requests are welcome on Stash at https://git.example.com/projects/GEM/repos/dry-request_handler/browse

