require 'capybara'
require 'capydash/dashboard_server'
require 'base64'
require 'fileutils'

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
      # emit "running" event first (without screenshot)
      CapyDash::EventEmitter.broadcast(
        step_name: step_name,
        detail: detail,
        test_name: (defined?(CapyDash) ? CapyDash.current_test : nil),
        status: "running"
      )

      # run the original step
      yield

      # take screenshot AFTER the action is completed
      base_dir = if CapyDash.respond_to?(:configuration)
        CapyDash.configuration&.screenshot_path || "tmp/capydash_screenshots"
      else
        "tmp/capydash_screenshots"
      end
      FileUtils.mkdir_p(base_dir) unless Dir.exist?(base_dir)
      timestamp = Time.now.strftime('%Y%m%d-%H%M%S-%L')
      safe_step = step_name.gsub(/\s+/, '_')
      screenshot_path = File.join(base_dir, "#{safe_step}-#{timestamp}.png")

      # Ensure we have an absolute path for Base64 encoding
      absolute_screenshot_path = File.absolute_path(screenshot_path)

      data_url = nil
      if defined?(Capybara)
        begin
          current_driver = Capybara.current_driver
          if current_driver != :rack_test
            if respond_to?(:page)
              page.save_screenshot(screenshot_path)
            else
              Capybara.current_session.save_screenshot(screenshot_path)
            end

            # Try to find the actual screenshot file location
            actual_screenshot_path = nil
            if File.exist?(absolute_screenshot_path)
              actual_screenshot_path = absolute_screenshot_path
            else
              # Check if it was saved in the capybara tmp directory
              capybara_path = File.join(Dir.pwd, "tmp", "capybara", screenshot_path)
              if File.exist?(capybara_path)
                actual_screenshot_path = capybara_path
              end
            end

            if actual_screenshot_path && File.exist?(actual_screenshot_path)
              encoded = Base64.strict_encode64(File.binread(actual_screenshot_path))
              data_url = "data:image/png;base64,#{encoded}"
            end
          end
        rescue => e
          # Silently handle screenshot capture failures
        end
      end

      # mark success with screenshot
      CapyDash::EventEmitter.broadcast(
        step_name: step_name,
        detail: detail,
        screenshot: actual_screenshot_path || screenshot_path,
        data_url: data_url,
        test_name: (defined?(CapyDash) ? CapyDash.current_test : nil),
        status: "passed"
      )
    rescue => e
      # take screenshot even on failure (after the action was attempted)
      base_dir = if CapyDash.respond_to?(:configuration)
        CapyDash.configuration&.screenshot_path || "tmp/capydash_screenshots"
      else
        "tmp/capydash_screenshots"
      end
      FileUtils.mkdir_p(base_dir) unless Dir.exist?(base_dir)
      timestamp = Time.now.strftime('%Y%m%d-%H%M%S-%L')
      safe_step = step_name.gsub(/\s+/, '_')
      screenshot_path = File.join(base_dir, "#{safe_step}-#{timestamp}.png")

      # Ensure we have an absolute path for Base64 encoding
      absolute_screenshot_path = File.absolute_path(screenshot_path)

      data_url = nil
      if defined?(Capybara)
        begin
          current_driver = Capybara.current_driver
          if current_driver != :rack_test
            if respond_to?(:page)
              page.save_screenshot(screenshot_path)
            else
              Capybara.current_session.save_screenshot(screenshot_path)
            end

            # Try to find the actual screenshot file location
            actual_screenshot_path = nil
            if File.exist?(absolute_screenshot_path)
              actual_screenshot_path = absolute_screenshot_path
            else
              # Check if it was saved in the capybara tmp directory
              capybara_path = File.join(Dir.pwd, "tmp", "capybara", screenshot_path)
              if File.exist?(capybara_path)
                actual_screenshot_path = capybara_path
              end
            end

            if actual_screenshot_path && File.exist?(actual_screenshot_path)
              encoded = Base64.strict_encode64(File.binread(actual_screenshot_path))
              data_url = "data:image/png;base64,#{encoded}"
            end
          end
        rescue => e
          # Silently handle screenshot capture failures
        end
      end

      CapyDash::EventEmitter.broadcast(
        step_name: step_name,
        detail: detail,
        screenshot: actual_screenshot_path || screenshot_path,
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
