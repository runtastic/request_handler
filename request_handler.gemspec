# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'request_handler/version'
Gem::Specification.new do |spec|
  spec.name          = 'request_handler'
  spec.version       = RequestHandler::VERSION
  spec.authors       = ['Andreas Eger', 'Dominik Goltermann']
  spec.email         = ['andreas.eger@runtastic.com', 'dominik.goltermann@runtastic.com']

  spec.summary       = 'shared base for request_handler using dry-* gems'
  spec.description   = 'shared base for request_handler using dry-* gems'
  spec.homepage      = 'https://github.com/runtastic/request_handler'
  spec.license       = 'MIT'
  spec.required_ruby_version = '~> 2.6'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'docile', '~> 1.3'
  spec.add_dependency 'multi_json', '~> 1.12'
  spec.add_dependency 'activesupport', '> 4.0'
  spec.add_dependency 'gem_config', '~> 0.3 '

  spec.add_development_dependency 'bundler'
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

  spec.add_development_dependency 'rack'

  spec.add_development_dependency 'definition', '~> 0.7'
end
