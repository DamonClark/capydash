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

  module Reporter
    def start_run
      @results = []
      @started_at = Time.now
    end

    def record_result(result_hash)
      return unless @started_at
      @results << result_hash
    end

    def generate_report
      return unless @started_at
      return if @results.empty?

      report_dir = File.join(Dir.pwd, "capydash_report")
      FileUtils.mkdir_p(report_dir)

      assets_dir = File.join(report_dir, "assets")
      FileUtils.mkdir_p(assets_dir)

      screenshots_dir = File.join(assets_dir, "screenshots")
      FileUtils.rm_rf(screenshots_dir)
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

    def normalize_status(status)
      case status
      when :passed, 'passed'
        'passed'
      when :failed, 'failed'
        'failed'
      when :pending, 'pending', :skipped, 'skipped'
        'pending'
      else
        status.to_s
      end
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

    private

    def generate_html(processed_tests, created_at, total_tests, passed_tests, failed_tests)
      processed_tests.each do |test_class|
        test_class[:methods].each do |method|
          method[:safe_id] = method[:name].gsub(/['"]/, '').gsub(/[^a-zA-Z0-9]/, '_')
        end
      end

      template_path = File.join(File.dirname(__FILE__), 'templates', 'report.html.erb')
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
      File.read(File.join(File.dirname(__FILE__), 'assets', 'dashboard.css'))
    end

    def generate_javascript
      File.read(File.join(File.dirname(__FILE__), 'assets', 'dashboard.js'))
    end
  end
end
