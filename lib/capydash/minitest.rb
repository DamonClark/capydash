require 'capydash/reporter'

module CapyDash
  module Minitest
    class Reporter < ::Minitest::AbstractReporter
      include CapyDash::Reporter

      def start
        start_run
      end

      def record(result)
        return unless @started_at

        status = if result.skipped?
                   'pending'
                 elsif result.passed?
                   'passed'
                 else
                   'failed'
                 end

        error_message = nil
        if result.failure
          error_message = format_exception(result.failure)
        end

        screenshot_path = nil
        if status == 'failed'
          # Rails system tests save screenshots before teardown to tmp/capybara/.
          # By the time the reporter's record() runs, the session is torn down,
          # so we look for the Rails-generated screenshot first.
          screenshot_path = find_rails_screenshot(result.name) || capture_screenshot
        end

        class_name = result.klass || 'UnknownTest'
        method_name = result.name.to_s.sub(/\Atest_/, '').tr('_', ' ')

        location = nil
        if result.respond_to?(:source_location) && result.source_location
          location = result.source_location.join(':')
        end

        record_result({
          class_name: class_name,
          method_name: method_name,
          status: status,
          error: error_message,
          location: location,
          screenshot_path: screenshot_path
        })
      end

      def report
        generate_report
      end

      def passed?
        true
      end

      private

      def find_rails_screenshot(test_name)
        path = File.join(Dir.pwd, "tmp", "capybara", "failures_#{test_name}.png")
        File.exist?(path) ? path : nil
      rescue
        nil
      end
    end
  end
end
