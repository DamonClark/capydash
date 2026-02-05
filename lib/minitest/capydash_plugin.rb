module Minitest
  def self.plugin_capydash_init(options)
    require 'capydash/minitest'
    self.reporter << CapyDash::Minitest::Reporter.new
  end
end
