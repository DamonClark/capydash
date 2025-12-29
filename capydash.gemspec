# capydash.gemspec
require_relative "lib/capydash/version"

Gem::Specification.new do |spec|
  spec.name          = "capydash"
  spec.version       = CapyDash::VERSION
  spec.authors       = ["Damon Clark"]
  spec.email         = ["dclark312@gmail.com"]

  spec.summary       = "Minimal static HTML report generator for RSpec system tests"
  spec.description   = "CapyDash automatically generates clean, readable HTML test reports after your RSpec suite finishes. Zero configuration required."
  spec.homepage      = "https://github.com/damonclark/capydash"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir["lib/**/*", "README.md", "LICENSE*", "*.gemspec"]
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_runtime_dependency "rspec", ">= 3.0"

  # Development dependencies
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "rails", ">= 6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
end
