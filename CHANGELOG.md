# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- possibility to send NULL values in relationships

## [0.15.0] - 2018-06-20
### Added
- JsonParser for non-jsonapi documents in body an multipart files

### Changed
- changelog format (previous logs kept mostly the same)

## [0.14.0] - 2017-09-11

- support generic query params

## [0.13.0] - 2017-07-28

- sidecar resources for multipart requests can be labeled with required
- **remove** support for sidepushing via `included` array in request body.

## [0.12.0] - 2017-05-19

- support for multipart-requests
- update rubocop and fix danger check
- drop support for ruby 2.1 (dry-types does not support it anymore either which makes supporting it here pointless)
- adapt fieldset validation to allow all fields in addition to a specific enum
- no need for 'required' field in fieldsets_parser anymore
- throw different errors for each parser, all new errors inherit from ExternalArgumentError

## [0.11.0] - 2017-03-17

- parse `included` array from request body
- body no longer accepts a default

## [0.10.0] - 2017-02-16

- raise an error if mandatory options are missing in the handler configuration
- transform param keys to string before substitution
- make gem compatible with ruby 2.1
- add danger
- raise an ExternalArgumentError if the body does not contain data

## [0.9.1] - 2017-01-31

- fix configure method

## [0.9.0] - 2017-01-31

- change nesting separator from `_` to `__` and use it consistently (also in sorting fields)
- make separator configurable


## [0.8.0] - 2017-01-10

- rename gem (dry-request_handler --> request_handler)
- remove env based config for logger

## [0.7.1] - 2017-01-04

- fix usage of struct to be unambiguous if dry-struct is used

## [0.7.0] - 2017-01-03

- fix error message building
- sort_params returns an array of SortOption structs now
- general `headers` method for all headers (removes `authorization_headers` method)
- sort and include options will use only the values from the request if they exist and the defaults if there are no values set in the request

## [0.6.0] - 2016-12-14

- support for fieldsets

## [0.5.0] - 2016-11-29

- `default_size` is now mandatory
- `default_size` and `max_size` now must be Integers

## [0.4.0] - 2016-11-16

fix error messages to also work with nested error messages

## [0.3.0] - 2016-11-08

sort_params returns an array of dtos now `DataTransferObject.new(field: "test", directions: :asc)`

## [0.2.1] - 2016-11-02

version bump for publishing

[Unreleased]: https://github.com/runtastic/request_handler/compare/v0.15.0...HEAD
[0.15.0]: https://github.com/runtastic/request_handler/compare/v0.14.0...v0.15.0
[0.14.0]: https://github.com/runtastic/request_handler/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/runtastic/request_handler/compare/v0.12.0...v0.13.0
