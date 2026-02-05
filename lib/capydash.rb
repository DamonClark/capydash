require "capydash/version"

# Auto-setup RSpec integration if RSpec is present and ready
if defined?(RSpec) && RSpec.respond_to?(:configure)
  require "capydash/rspec"
  CapyDash::RSpec.setup!
elsif defined?(Rails) && defined?(Rails::Railtie)
  # In Rails, RSpec might load after the gem, so defer setup
  class CapyDash::Railtie < Rails::Railtie
    config.after_initialize do
      if defined?(RSpec) && RSpec.respond_to?(:configure)
        require "capydash/rspec" unless defined?(CapyDash::RSpec)
        CapyDash::RSpec.setup!
      end
    end
  end
end

# Minitest integration is handled automatically via the minitest plugin system.
# Minitest discovers lib/minitest/capydash_plugin.rb and calls
# plugin_capydash_init during Minitest.run, which adds our reporter.
