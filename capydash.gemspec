# capydash.gemspec
Gem::Specification.new do |spec|
  spec.name          = "capydash"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]

  spec.summary       = "Real-time Capybara test dashboard"
  spec.description   = "CapyDash instruments Capybara tests and streams test steps, screenshots, and DOM snapshots to a live dashboard."
  spec.homepage      = "https://github.com/yourusername/capydash"
  spec.license       = "MIT"

  # Main file
  spec.files         = Dir["lib/**/*.rb"] + Dir["README.md"]
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_runtime_dependency "capybara", ">= 3.0"
  spec.add_runtime_dependency "faye-websocket"
  spec.add_runtime_dependency "eventmachine"
  spec.add_runtime_dependency "em-websocket"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rails", "~> 7.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'https://rubygems.org'"
end
