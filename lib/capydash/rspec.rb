require 'time'
require 'fileutils'
require 'erb'
require 'cgi'
require 'tmpdir'

module CapyDash
  class ReportData
    attr_reader :processed_tests, :created_at, :total_tests, :passed_tests, :failed_tests

    def initialize(processed_tests:, created_at:, total_tests:, passed_tests:, failed_tests:)
      @processed_tests = processed_tests
      @created_at = created_at
      @total_tests = total_tests
      @passed_tests = passed_tests
      @failed_tests = failed_tests
    end

    def h(text)
      CGI.escapeHTML(text.to_s)
    end

    def get_binding
      binding
    end
  end

  module RSpec
    class << self
      # Public method: Called from RSpec before(:suite) hook
      def start_run
        @results = []
        @started_at = Time.now
      end

      # Public method: Called from RSpec after(:each) hook
      def record_example(example)
        return unless @started_at

        execution_result = example.execution_result
        status = normalize_status(execution_result.status)

        error_message = nil
        if execution_result.status == :failed && execution_result.exception
          error_message = format_exception(execution_result.exception)
        end

        screenshot_path = nil
        if status == 'failed'
          screenshot_path = capture_screenshot
        end

        class_name = extract_class_name(example)

        @results << {
          class_name: class_name,
          method_name: example.full_description,
          status: status,
          error: error_message,
          location: example.metadata[:location],
          screenshot_path: screenshot_path
        }
      end

      # Public method: Called from RSpec after(:suite) hook
      def generate_report
        return unless @started_at
        return if @results.empty?

        report_dir = File.join(Dir.pwd, "capydash_report")
        FileUtils.mkdir_p(report_dir)

        assets_dir = File.join(report_dir, "assets")
        FileUtils.mkdir_p(assets_dir)

        screenshots_dir = File.join(assets_dir, "screenshots")
        FileUtils.mkdir_p(screenshots_dir)

        # Group results by class
        tests_by_class = @results.group_by { |r| r[:class_name] }

        # Calculate statistics
        total_tests = @results.length
        passed_tests = @results.count { |r| r[:status] == 'passed' }
        failed_tests = @results.count { |r| r[:status] == 'failed' }

        # Copy screenshots into report and build relative paths
        screenshot_index = 0
        @results.each do |result|
          if result[:screenshot_path] && File.exist?(result[:screenshot_path])
            screenshot_index += 1
            dest_name = format("%03d.png", screenshot_index)
            dest_path = File.join(screenshots_dir, dest_name)
            FileUtils.cp(result[:screenshot_path], dest_path)
            result[:screenshot_relative] = "assets/screenshots/#{dest_name}"
          end
        end

        # Process for template
        processed_tests = tests_by_class.map do |class_name, examples|
          {
            class_name: class_name,
            methods: examples.map do |ex|
              {
                name: ex[:method_name],
                status: ex[:status],
                steps: [{
                  name: 'test_execution',
                  detail: ex[:method_name],
                  status: ex[:status],
                  error: ex[:error],
                  screenshot: ex[:screenshot_relative]
                }]
              }
            end
          }
        end

        # Generate HTML
        html_content = generate_html(processed_tests, @started_at, total_tests, passed_tests, failed_tests)
        File.write(File.join(report_dir, "index.html"), html_content)

        # Generate CSS
        css_content = generate_css
        File.write(File.join(assets_dir, "dashboard.css"), css_content)

        # Generate JS
        js_content = generate_javascript
        File.write(File.join(assets_dir, "dashboard.js"), js_content)

        report_dir
      end

      # Public method: Sets up RSpec hooks
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
          # If RSpec isn't ready, silently fail - it will be set up later
          @configured = false
        end
      end

      private

      def rspec_available?
        return false unless defined?(::RSpec)
        return false unless ::RSpec.respond_to?(:configure)
        true
      rescue
        false
      end

      def normalize_status(status)
        case status
        when :passed, 'passed'
          'passed'
        when :failed, 'failed'
          'failed'
        when :pending, 'pending'
          'pending'
        else
          status.to_s
        end
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

      def capture_screenshot
        return nil unless defined?(::Capybara) && defined?(::Capybara.current_session)

        session = ::Capybara.current_session
        return nil unless session.respond_to?(:save_screenshot)

        tmpfile = File.join(Dir.tmpdir, "capydash_#{Time.now.to_i}_#{rand(10000)}.png")
        session.save_screenshot(tmpfile)
        tmpfile
      rescue => _e
        nil
      end

      def format_exception(exception)
        return nil unless exception

        message = exception.message || 'Unknown error'
        backtrace = exception.backtrace || []

        formatted = "#{exception.class}: #{message}"
        if backtrace.any?
          formatted += "\n" + backtrace.first(5).map { |line| "  #{line}" }.join("\n")
        end

        formatted
      end

      def generate_html(processed_tests, created_at, total_tests, passed_tests, failed_tests)
        # Create safe IDs for method names (escape special chars for HTML/JS)
        processed_tests.each do |test_class|
          test_class[:methods].each do |method|
            method[:safe_id] = method[:name].gsub(/['"]/, '').gsub(/[^a-zA-Z0-9]/, '_')
          end
        end

        template_path = File.join(__dir__, 'templates', 'report.html.erb')
        template = File.read(template_path)
        erb = ERB.new(template)

        report_data = CapyDash::ReportData.new(
          processed_tests: processed_tests,
          created_at: created_at,
          total_tests: total_tests,
          passed_tests: passed_tests,
          failed_tests: failed_tests
        )

        erb.result(report_data.get_binding)
      end

      def generate_css
        File.read(File.join(__dir__, 'assets', 'dashboard.css'))
      end

      def generate_javascript
        File.read(File.join(__dir__, 'assets', 'dashboard.js'))
      end
    end
  end
end
