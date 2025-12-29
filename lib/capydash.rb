require "capydash/version"

# Auto-setup RSpec integration if RSpec is present and ready
if defined?(RSpec) && RSpec.respond_to?(:configure)
  require "capydash/rspec"
  CapyDash::RSpec.setup!
elsif defined?(Rails)
  # In Rails, RSpec might load after the gem, so set up a hook
  Rails.application.config.after_initialize do
    if defined?(RSpec) && RSpec.respond_to?(:configure)
      require "capydash/rspec" unless defined?(CapyDash::RSpec)
      CapyDash::RSpec.setup!
    end
  end
end
