require 'time'
require 'fileutils'
require 'erb'

module CapyDash
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

        file_path = example.metadata[:file_path] || ''
        class_name = extract_class_name(file_path)

        @results << {
          class_name: class_name,
          method_name: example.full_description,
          status: status,
          error: error_message,
          location: example.metadata[:location]
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

        # Group results by class
        tests_by_class = @results.group_by { |r| r[:class_name] }

        # Calculate statistics
        total_tests = @results.length
        passed_tests = @results.count { |r| r[:status] == 'passed' }
        failed_tests = @results.count { |r| r[:status] == 'failed' }

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
                  error: ex[:error]
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
        # Normalize RSpec status symbols to strings
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

      def extract_class_name(file_path)
        return 'UnknownSpec' if file_path.nil? || file_path.empty?

        filename = File.basename(file_path, '.rb')
        filename.split('_').map(&:capitalize).join('')
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

        erb.result(binding)
      end

      def generate_css
        <<~CSS
          * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
          }

          body {
              font-family: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
              line-height: 1.6;
              color: #333;
              background-color: #f8f9fa;
          }

          .container {
              max-width: 1400px;
              margin: 0 auto;
              padding: 1rem;
          }

          .header {
              background: white;
              padding: 1.5rem;
              border-radius: 8px;
              box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              margin-bottom: 1.5rem;
          }

          .header h1 {
              font-size: 2rem;
              margin-bottom: 0.5rem;
              color: #2c3e50;
          }

          .header .subtitle {
              color: #666;
              font-size: 0.9rem;
              margin-bottom: 1rem;
          }

          .search-container {
              margin-top: 1rem;
          }

          .search-input {
              width: 100%;
              padding: 0.75rem 1rem;
              border: 2px solid #ddd;
              border-radius: 6px;
              font-size: 1rem;
              transition: border-color 0.2s;
          }

          .search-input:focus {
              outline: none;
              border-color: #3498db;
              box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1);
          }

          .summary {
              display: grid;
              grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
              gap: 1rem;
              margin-bottom: 1.5rem;
          }

          .summary-card {
              background: white;
              padding: 1.5rem;
              border-radius: 8px;
              box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              text-align: center;
          }

          .summary-card .number {
              font-size: 2.5rem;
              font-weight: bold;
              margin-bottom: 0.5rem;
          }

          .summary-card.total .number {
              color: #3498db;
          }

          .summary-card.passed .number {
              color: #27ae60;
          }

          .summary-card.failed .number {
              color: #e74c3c;
          }

          .summary-card .label {
              color: #666;
              font-size: 0.9rem;
              text-transform: uppercase;
              letter-spacing: 0.5px;
          }

          .test-results {
              background: white;
              border-radius: 8px;
              box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              overflow: hidden;
          }

          .test-class {
              border-bottom: 1px solid #eee;
          }

          .test-class:last-child {
              border-bottom: none;
          }

          .test-class.hidden {
              display: none;
          }

          .test-class h2 {
              background: #f8f9fa;
              padding: 1rem 1.5rem;
              margin: 0;
              font-size: 1.25rem;
              color: #2c3e50;
              border-bottom: 1px solid #eee;
          }

          .test-method {
              padding: 1.5rem;
              border-bottom: 1px solid #f0f0f0;
          }

          .test-method:last-child {
              border-bottom: none;
          }

          .test-method.hidden {
              display: none;
          }

          .test-method-header {
              display: flex;
              align-items: center;
              margin-bottom: 1rem;
              cursor: pointer;
              gap: 0.75rem;
          }

          .test-method h3 {
              margin: 0;
              font-size: 1.1rem;
              color: #34495e;
              flex: 1;
          }

          .method-status {
              display: inline-flex;
              align-items: center;
              padding: 0.35rem 0.85rem;
              border-radius: 4px;
              font-size: 0.75rem;
              font-weight: 600;
              text-transform: uppercase;
              letter-spacing: 0.5px;
              white-space: nowrap;
              min-width: 60px;
              justify-content: center;
          }

          .method-status-passed {
              background-color: #27ae60;
              color: white;
          }

          .method-status-failed {
              background-color: #e74c3c;
              color: white;
          }

          .method-status-pending {
              background-color: #f39c12;
              color: white;
          }

          .expand-toggle {
              background: none;
              border: none;
              cursor: pointer;
              padding: 0.5rem;
              border-radius: 4px;
              transition: background-color 0.2s;
          }

          .expand-toggle:hover {
              background-color: #f0f0f0;
          }

          .expand-icon {
              font-size: 0.8rem;
              color: #666;
          }

          .steps {
              display: flex;
              flex-direction: column;
              gap: 1rem;
              transition: max-height 0.3s ease-out;
              overflow: hidden;
          }

          .steps.collapsed {
              max-height: 0;
              margin: 0;
          }

          .step {
              border: 1px solid #ddd;
              border-radius: 6px;
              padding: 1rem;
              background: #fafafa;
          }

          .step.passed {
              border-color: #27ae60;
              background: #f8fff8;
          }

          .step.failed {
              border-color: #e74c3c;
              background: #fff8f8;
          }

          .step-header {
              display: flex;
              justify-content: space-between;
              align-items: center;
              margin-bottom: 0.5rem;
          }

          .step-name {
              font-weight: 600;
              color: #2c3e50;
          }

          .step-status {
              padding: 0.25rem 0.5rem;
              border-radius: 4px;
              font-size: 0.8rem;
              font-weight: 600;
              text-transform: uppercase;
          }

          .step.passed .step-status {
              background: #27ae60;
              color: white;
          }

          .step.failed .step-status {
              background: #e74c3c;
              color: white;
          }

          .step-detail {
              color: #666;
              font-size: 0.9rem;
              margin-bottom: 0.5rem;
          }

          .error-log {
              margin-top: 1rem;
              padding: 1rem;
              background: #fff5f5;
              border: 1px solid #fed7d7;
              border-radius: 6px;
          }

          .error-log h4 {
              color: #e53e3e;
              margin: 0 0 0.5rem 0;
              font-size: 0.9rem;
          }

          .error-log pre {
              background: #2d3748;
              color: #e2e8f0;
              padding: 1rem;
              border-radius: 4px;
              overflow-x: auto;
              font-size: 0.8rem;
              line-height: 1.4;
              margin: 0;
              white-space: pre-wrap;
              word-wrap: break-word;
          }
        CSS
      end

      def generate_javascript
        <<~JS
          function toggleTestMethod(safeId) {
              const stepsContainer = document.getElementById('steps-' + safeId);
              const button = document.querySelector('[onclick*="' + safeId + '"]');

              if (stepsContainer && button) {
                  const icon = button.querySelector('.expand-icon');
                  if (icon) {
                      const isCollapsed = stepsContainer.classList.contains('collapsed');

                      if (isCollapsed) {
                          stepsContainer.classList.remove('collapsed');
                          icon.textContent = '▼';
                      } else {
                          stepsContainer.classList.add('collapsed');
                          icon.textContent = '▶';
                      }
                  }
              }
          }

          // Search functionality
          document.addEventListener('DOMContentLoaded', function() {
              const searchInput = document.getElementById('searchInput');
              if (!searchInput) return;

              searchInput.addEventListener('input', function(e) {
                  const query = e.target.value.toLowerCase().trim();
                  const testMethods = document.querySelectorAll('.test-method');
                  const testClasses = document.querySelectorAll('.test-class');

                  // Determine if query is a status filter
                  const isStatusFilter = query === 'pass' || query === 'fail' ||
                                        query === 'passed' || query === 'failed' ||
                                        query === 'pending';

                  testMethods.forEach(function(method) {
                      const name = method.getAttribute('data-name') || '';
                      const status = method.getAttribute('data-status') || '';

                      let shouldShow = false;

                      if (!query) {
                          // No query - show all
                          shouldShow = true;
                      } else if (isStatusFilter) {
                          // Status filter - check status
                          shouldShow = (query === 'pass' && status === 'passed') ||
                                      (query === 'fail' && status === 'failed') ||
                                      query === status;
                      } else {
                          // Name filter - check if name contains query
                          shouldShow = name.includes(query);
                      }

                      if (shouldShow) {
                          method.classList.remove('hidden');
                      } else {
                          method.classList.add('hidden');
                      }
                  });

                  // Hide test classes if all methods are hidden
                  testClasses.forEach(function(testClass) {
                      const visibleMethods = testClass.querySelectorAll('.test-method:not(.hidden)');
                      if (visibleMethods.length === 0) {
                          testClass.classList.add('hidden');
                      } else {
                          testClass.classList.remove('hidden');
                      }
                  });
              });
          });
        JS
      end
    end
  end
end
