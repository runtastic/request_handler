# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "request_handler/version"
Gem::Specification.new do |spec|
  spec.name          = "request_handler"
  spec.version       = RequestHandler::VERSION
  spec.authors       = ["Andreas Eger", "Dominik Goltermann"]
  spec.email         = ["andreas.eger@runtastic.com", "dominik.goltermann@runtastic.com"]

  spec.summary       = "shared base for request_handler using dry-* gems"
  spec.description   = "shared base for request_handler using dry-* gems"
  spec.homepage      = "https://github.com/runtastic/request_handler"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", "> 4.0"
  spec.add_runtime_dependency "docile", "~> 1.3"
  spec.add_runtime_dependency "gem_config", "~> 0.3 "
  spec.add_runtime_dependency "multi_json", "~> 1.12"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "codecov"
  spec.add_development_dependency "danger"
  spec.add_development_dependency "danger-commit_lint"
  spec.add_development_dependency "danger-rubocop"
  spec.add_development_dependency "definition", "~> 0.7"
  spec.add_development_dependency "dry-types", "~> 1.0"
  spec.add_development_dependency "dry-validation", "~> 1.0"
  spec.add_development_dependency "fuubar", "~> 2.2"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-rubocop"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "rt_rubocop_defaults", "~> 2.5"
  spec.add_development_dependency "rubocop", "~> 1.44"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 2.18"
  spec.add_development_dependency "rubocop_runner", "~> 2.0"
  spec.add_development_dependency "simplecov"

  spec.metadata["rubygems_mfa_required"] = "true"
end
