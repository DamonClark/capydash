# capydash.gemspec
require_relative "lib/capydash/version"

Gem::Specification.new do |spec|
  spec.name          = "capydash"
  spec.version       = Capydash::VERSION
  spec.authors       = ["Damon Clark"]
  spec.email         = ["dclark312@gmail.com"]

  spec.summary       = "Real-time Capybara test dashboard"
  spec.description   = "CapyDash instruments Capybara tests and streams test steps, screenshots, and DOM snapshots to a live dashboard."
  spec.homepage      = "https://github.com/damonclark/capydash"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir["lib/**/*", "bin/*", "README.md", "LICENSE*", "*.gemspec"]
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_runtime_dependency "capybara", ">= 3.0"
  spec.add_runtime_dependency "faye-websocket"
  spec.add_runtime_dependency "eventmachine"
  spec.add_runtime_dependency "em-websocket"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rails", "~> 7.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
end
