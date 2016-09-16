# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/request_handler/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-request_handler"
  spec.version       = Dry::RequestHandler::VERSION
  spec.authors       = ["Andreas Eger"]
  spec.email         = ["dev@eger-andreas.de"]

  spec.summary       = "shared base for request_handler using dry-* gems"
  spec.description   = "shared base for request_handler using dry-* gems"
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://gems.example.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_development_dependency "rubocop_runner", "~> 2.0"
  spec.add_development_dependency "rubocop-defaults", "~> 2.0.1"
  spec.add_development_dependency "geminabox-release"

  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency "guard-rubocop"
end
