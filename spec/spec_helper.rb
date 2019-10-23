# frozen_string_literal: true

ENV['RACK_ENV'] = ENV['ENVIRONMENT'] ||= 'test'
require 'simplecov'
if ENV['CIRCLECI']
  require 'codecov'
  SimpleCov.formatter SimpleCov::Formatter::Codecov
end
SimpleCov.start do
  add_filter '/spec/'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'request_handler'
require 'pry'
require 'ostruct'
require 'rack'

[
  'spec/support/**/*.rb'
].each do |pattern|
  Dir[File.join(pattern)].sort.each { |file| require "./#{file}" }
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.default_formatter = 'doc' if config.files_to_run.one?
  config.profile_examples = 5

  config.order = :random
  Kernel.srand config.seed

  # enable aggregate failures by default
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end

  config.before(:example) do
    RequestHandler.configure do |rh_config|
      rh_config.validation_engine = RequestHandler::Validation::DryEngine
      rh_config.raise_jsonapi_errors = true
    end
  end
end
