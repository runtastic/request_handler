Changelog
===

## master

- fix error message building
- sort_params returns an array of SortOption structs now
- general `headers` method for all headers (removes `authorization_headers` method)

##0.6

- support for fieldsets

##0.5

- `default_size` is now mandatory
- `default_size` and `max_size` now must be Integers

##0.4 Bugfix

fix error messages to also work with nested error messages

##0.3

sort_params returns an array of dtos now `DataTransferObject.new(field: "test", directions: :asc)`

##0.2

version bump for publishing 

##0.1

Initial Gem
