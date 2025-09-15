require 'capybara'
require 'capydash/dashboard_server'
require 'base64'
require 'fileutils'

puts "[CapyDash] Instrumentation file loaded"

module CapyDash
  module Instrumentation
    def visit(path)
      emit_step("visit", path) { super(path) }
    end

    def click_button(*args)
      emit_step("click_button", args.first) { super(*args) }
    end

    def fill_in(locator, with:)
      emit_step("fill_in", "#{locator} => #{with}") { super(locator, with: with) }
    end

    private

    def emit_step(step_name, detail)
      # take screenshot
      base_dir = if CapyDash.respond_to?(:configuration)
        CapyDash.configuration&.screenshot_path || "tmp/capydash_screenshots"
      else
        "tmp/capydash_screenshots"
      end
      FileUtils.mkdir_p(base_dir) unless Dir.exist?(base_dir)
      timestamp = Time.now.strftime('%Y%m%d-%H%M%S-%L')
      safe_step = step_name.gsub(/\s+/, '_')
      screenshot_path = File.join(base_dir, "#{safe_step}-#{timestamp}.png")

      data_url = nil
      if defined?(Capybara)
        begin
          current_driver = Capybara.current_driver
          puts "[CapyDash] Current Capybara driver: #{current_driver}"
          if current_driver == :rack_test
            puts "[CapyDash] Skipping screenshot (rack_test driver)"
          else
            if respond_to?(:page)
              page.save_screenshot(screenshot_path)
            else
              Capybara.current_session.save_screenshot(screenshot_path)
            end
            puts "[CapyDash] Saved screenshot: #{screenshot_path}"
            if File.exist?(screenshot_path)
              encoded = Base64.strict_encode64(File.binread(screenshot_path))
              data_url = "data:image/png;base64,#{encoded}"
            end
          end
        rescue => e
          warn "[CapyDash] Screenshot capture failed: #{e.message}"
        end
      end

      # emit event
      CapyDash::EventEmitter.broadcast(
        step_name: step_name,
        detail: detail,
        screenshot: screenshot_path,
        data_url: data_url,
        test_name: (defined?(CapyDash) ? CapyDash.current_test : nil),
        status: "running"
      )

      # run the original step
      yield

      # mark success
      CapyDash::EventEmitter.broadcast(
        step_name: step_name,
        detail: detail,
        screenshot: screenshot_path,
        data_url: data_url,
        test_name: (defined?(CapyDash) ? CapyDash.current_test : nil),
        status: "passed"
      )
    rescue => e
      CapyDash::EventEmitter.broadcast(
        step_name: step_name,
        detail: detail,
        screenshot: screenshot_path,
        data_url: data_url,
        test_name: (defined?(CapyDash) ? CapyDash.current_test : nil),
        status: "failed",
        error: e.message
      )
      raise e
    end
  end
end

# Prepend into Capybara DSL so it wraps all calls
Capybara::Session.prepend(CapyDash::Instrumentation)
puts "[CapyDash] Instrumentation prepended into Capybara::Session"
