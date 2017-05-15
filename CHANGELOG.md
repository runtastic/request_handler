Changelog
===

## master
- support for multipart-requests
- update rubocop and fix danger check
- drop support for ruby 2.1 (dry-types does not support it anymore either which makes supporting it here pointless)

## 0.11.0

- Parse `included` array from request body
- Body no longer accepts a default

## 0.10.0

- raise an error if mandatory options are missing in the handler configuration
- Transform param keys to string before substitution
- make gem compatible with ruby 2.1
- add danger
- raise an ExternalArgumentError if the body does not contain data

## 0.9.1

- fix configure method

## 0.9.0

- change nesting separator from `_` to `__` and use it consistently (also in sorting fields)
- make separator configurable


## 0.8.0
- rename gem (dry-request_handler --> request_handler)
- remove env based config for logger

## 0.7.1

- fix usage of struct to be unambiguous if dry-struct is used

## 0.7

- fix error message building
- sort_params returns an array of SortOption structs now
- general `headers` method for all headers (removes `authorization_headers` method)
- sort and include options will use only the values from the request if they exist and the defaults if there are no values set in the request

## 0.6

- support for fieldsets

## 0.5

- `default_size` is now mandatory
- `default_size` and `max_size` now must be Integers

## 0.4

fix error messages to also work with nested error messages

## 0.3

sort_params returns an array of dtos now `DataTransferObject.new(field: "test", directions: :asc)`

## 0.2

version bump for publishing

## 0.1

Initial Gem
