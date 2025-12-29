require 'time'
require 'securerandom'
require 'fileutils'
require 'erb'

module CapyDash
  module RSpecIntegration
    class << self
      def setup!
        return unless defined?(RSpec)
        return if @configured

        @results = []
        @run_id = nil
        @configured = true

        RSpec.configure do |config|
          config.before(:suite) do
            CapyDash::RSpecIntegration.start_test_run
          end

          config.after(:each) do |example|
            CapyDash::RSpecIntegration.record_example(example)
          end

          config.after(:suite) do
            CapyDash::RSpecIntegration.finish_test_run
          end
        end
      end

      def start_test_run
        @run_id = generate_run_id
        @results = []
        @started_at = Time.now
      end

      def record_example(example)
        return unless @run_id

        execution_result = example.execution_result

        # Map RSpec status to our status format
        status = case execution_result.status.to_s
        when 'passed'
          'passed'
        when 'failed'
          'failed'
        when 'pending'
          'pending'
        else
          'unknown'
        end

        # Extract error message if test failed
        error_message = nil
        if execution_result.status == :failed && execution_result.exception
          error_message = format_exception(execution_result.exception)
        end

        # Extract class name from example location
        # RSpec examples are typically in files like spec/features/user_spec.rb
        # We'll use the file path to determine the "class" name
        file_path = example.metadata[:file_path] || ''
        class_name = extract_class_name_from_path(file_path)

        # Create test data structure matching Minitest format
        test_data = {
          test_name: "#{class_name}##{example.full_description}",
          steps: [
            {
              step_name: 'test_execution',
              detail: example.full_description,
              status: status,
              error: error_message
            }
          ]
        }

        # Add location information
        if example.metadata[:location]
          test_data[:location] = example.metadata[:location]
        end

        @results << test_data
      end

      def finish_test_run
        return unless @run_id
        return if @results.empty?

        # Calculate summary statistics
        total_tests = @results.length
        passed_tests = @results.count { |r| r[:steps].any? { |s| s[:status] == 'passed' } }
        failed_tests = @results.count { |r| r[:steps].any? { |s| s[:status] == 'failed' } }
        pending_tests = @results.count { |r| r[:steps].any? { |s| s[:status] == 'pending' } }

        # Create run data structure matching Minitest format
        run_data = {
          id: @run_id,
          created_at: @started_at.iso8601,
          total_tests: total_tests,
          passed_tests: passed_tests,
          failed_tests: failed_tests,
          tests: @results.map { |r| { test_name: r[:test_name], steps: r[:steps] } }
        }

        # Save using the existing persistence layer
        CapyDash.save_test_run(run_data)

        # Generate report
        generate_report(run_data)

        # Clear state
        @run_id = nil
        @results = []
      end

      private

      def generate_run_id
        "#{Time.now.to_i}_#{SecureRandom.hex(4)}"
      end

      def extract_class_name_from_path(file_path)
        return 'UnknownSpec' if file_path.nil? || file_path.empty?

        # Extract filename without extension and path
        filename = File.basename(file_path, '.rb')

        # Convert snake_case to PascalCase
        # e.g., "user_spec" -> "UserSpec", "features/user_flow_spec" -> "UserFlowSpec"
        filename.split('_').map(&:capitalize).join('')
      end

      def format_exception(exception)
        return nil unless exception

        message = exception.message || 'Unknown error'
        backtrace = exception.backtrace || []

        # Format similar to RSpec's output
        formatted = "#{exception.class}: #{message}"

        if backtrace.any?
          # Include first few lines of backtrace
          formatted += "\n" + backtrace.first(5).map { |line| "  #{line}" }.join("\n")
        end

        formatted
      end

      def generate_report(run_data)
        # Use the existing ReportGenerator but with our RSpec data
        # We need to adapt it to work with our in-memory data structure
        report_dir = File.join(Dir.pwd, "capydash_report")
        FileUtils.mkdir_p(report_dir)

        assets_dir = File.join(report_dir, "assets")
        FileUtils.mkdir_p(assets_dir)

        screenshots_dir = File.join(report_dir, "screenshots")
        FileUtils.mkdir_p(screenshots_dir)

        # Generate HTML report using the same template
        html_content = generate_html(run_data, run_data[:created_at])
        html_path = File.join(report_dir, "index.html")
        File.write(html_path, html_content)

        # Generate CSS and JS - use ReportGenerator's private methods via send
        # These methods are private but we need them for RSpec reports
        css_content = CapyDash::ReportGenerator.send(:generate_css)
        css_path = File.join(assets_dir, "dashboard.css")
        File.write(css_path, css_content)

        js_content = CapyDash::ReportGenerator.send(:generate_javascript)
        js_path = File.join(assets_dir, "dashboard.js")
        File.write(js_path, js_content)

        html_path
      end

      def generate_html(test_data, created_at)
        # Process test data into a structured format (same as ReportGenerator)
        processed_tests = process_test_data(test_data)

        # Calculate summary statistics
        total_tests = processed_tests.sum { |test| test[:methods].length }
        passed_tests = processed_tests.sum { |test| test[:methods].count { |method| method[:status] == 'passed' } }
        failed_tests = total_tests - passed_tests

        # Parse created_at if it's a string, otherwise use Time object
        created_at_time = if created_at.is_a?(String)
          Time.parse(created_at)
        else
          created_at
        end

        # Generate HTML using ERB template
        template = File.read(File.join(__dir__, 'templates', 'report.html.erb'))
        erb = ERB.new(template)

        erb.result(binding)
      end

      def process_test_data(test_data)
        return [] unless test_data[:tests]

        # Group tests by class
        tests_by_class = {}

        test_data[:tests].each do |test|
          test_name = test[:test_name] || 'UnknownTest'

          # Extract class and method names from test name like "UserSpec#should visit the home page"
          if test_name.include?('#')
            class_name, method_name = test_name.split('#', 2)
          else
            class_name = extract_class_name(test_name)
            method_name = extract_method_name(test_name)
          end

          tests_by_class[class_name] ||= {
            class_name: class_name,
            methods: []
          }

          # Process steps
          steps = test[:steps] || []
          processed_steps = steps.map do |step|
            {
              name: step[:step_name] || step[:name] || 'unknown_step',
              detail: step[:detail] || step[:description] || '',
              status: step[:status] || 'unknown',
              screenshot: step[:screenshot] ? File.basename(step[:screenshot]) : nil,
              error: step[:error] || step[:message]
            }
          end

          # Filter out "running" steps
          processed_steps = processed_steps.reject { |step| step[:status] == 'running' }

          # Determine method status
          method_status = if processed_steps.any? { |s| s[:status] == 'failed' }
            'failed'
          elsif processed_steps.any? { |s| s[:status] == 'passed' }
            'passed'
          elsif processed_steps.any? { |s| s[:status] == 'pending' }
            'pending'
          else
            'running'
          end

          tests_by_class[class_name][:methods] << {
            name: method_name,
            status: method_status,
            steps: processed_steps
          }
        end

        tests_by_class.values
      end

      def extract_class_name(test_name)
        return 'UnknownTest' if test_name.nil? || test_name.empty?

        if test_name.include?('#')
          test_name.split('#').first
        else
          test_name
        end
      end

      def extract_method_name(test_name)
        return 'unknown_method' if test_name.nil? || test_name.empty?

        if test_name.include?('#')
          test_name.split('#').last
        else
          test_name
        end
      end
    end
  end
end
