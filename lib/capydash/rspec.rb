require 'capydash/reporter'

module CapyDash
  module RSpec
    extend CapyDash::Reporter

    class << self
      def setup!
        return unless rspec_available?
        return if @configured

        begin
          @configured = true
          @results = []
          @started_at = nil

          ::RSpec.configure do |config|
            config.before(:suite) do
              CapyDash::RSpec.start_run
            end

            config.after(:each) do |example|
              CapyDash::RSpec.record_example(example)
            end

            config.after(:suite) do
              CapyDash::RSpec.generate_report
            end
          end
        rescue => e
          @configured = false
        end
      end

      def record_example(example)
        return unless @started_at

        execution_result = example.execution_result

        # Derive status from exception since execution_result.status
        # is not yet set during after(:each) hooks
        status = if example.pending? || example.skipped?
                   'pending'
                 elsif execution_result.exception
                   'failed'
                 else
                   'passed'
                 end

        error_message = nil
        if execution_result.exception
          error_message = format_exception(execution_result.exception)
        end

        screenshot_path = nil
        if status == 'failed'
          screenshot_path = capture_screenshot
        end

        class_name = extract_class_name(example)

        record_result({
          class_name: class_name,
          method_name: example.full_description,
          status: status,
          error: error_message,
          location: example.metadata[:location],
          screenshot_path: screenshot_path
        })
      end

      private

      def rspec_available?
        return false unless defined?(::RSpec)
        return false unless ::RSpec.respond_to?(:configure)
        true
      rescue
        false
      end

      def extract_class_name(example)
        group = example.metadata[:example_group]
        while group && group[:parent_example_group]
          group = group[:parent_example_group]
        end

        if group && group[:description] && !group[:description].to_s.empty?
          group[:description].to_s
        else
          file_path = example.metadata[:file_path] || ''
          return 'UnknownSpec' if file_path.empty?
          filename = File.basename(file_path, '.rb')
          filename.split('_').map(&:capitalize).join('')
        end
      end
    end
  end
end
