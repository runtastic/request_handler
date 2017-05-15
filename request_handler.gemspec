# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'request_handler/version'
Gem::Specification.new do |spec|
  spec.name          = 'request_handler'
  spec.version       = RequestHandler::VERSION
  spec.authors       = ['Andreas Eger', 'Raphael Hetzel']
  spec.email         = ['andreas.eger@runtastic.com', 'raphael.hetzel@runtastic.com']

  spec.summary       = 'shared base for request_handler using dry-* gems'
  spec.description   = 'shared base for request_handler using dry-* gems'
  spec.homepage      = 'https://github.com/runtastic/request_handler'
  spec.license       = 'MIT'
  spec.required_ruby_version = '~> 2.2'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-validation', '~> 0.10.4'
  spec.add_dependency 'confstruct', '~> 1.0.2'
  spec.add_dependency 'multi_json', '~> 1.12'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'fuubar', '~> 2.2'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'codecov'

  spec.add_development_dependency 'rubocop_runner', '~> 2.0'
  spec.add_development_dependency 'rubocop', '~> 0.48.1'

  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
end
