require 'json'
require 'fileutils'
require 'time'
require 'erb'

module CapyDash
  class ReportGenerator
    class << self
      def generate_report
        # Find the most recent test run data
        test_runs = CapyDash::Persistence.list_test_runs(1)
        return nil if test_runs.empty?

        latest_run = test_runs.first
        test_data = CapyDash::Persistence.load_test_run(latest_run[:id])
        return nil unless test_data

        # Create report directory
        report_dir = File.join(Dir.pwd, "capydash_report")
        FileUtils.mkdir_p(report_dir)

        # Create assets directory
        assets_dir = File.join(report_dir, "assets")
        FileUtils.mkdir_p(assets_dir)

        # Create screenshots directory
        screenshots_dir = File.join(report_dir, "screenshots")
        FileUtils.mkdir_p(screenshots_dir)

        # Copy screenshots from test data
        copy_screenshots(test_data, screenshots_dir)

        # Generate HTML report
        html_content = generate_html(test_data, latest_run[:created_at])
        html_path = File.join(report_dir, "index.html")
        File.write(html_path, html_content)

        # Generate CSS
        css_content = generate_css
        css_path = File.join(assets_dir, "dashboard.css")
        File.write(css_path, css_content)

        # Generate JavaScript
        js_content = generate_javascript
        js_path = File.join(assets_dir, "dashboard.js")
        File.write(js_path, js_content)

        html_path
      end

      private

      def copy_screenshots(test_data, screenshots_dir)
        return unless test_data[:tests]

        test_data[:tests].each do |test|
          next unless test[:steps]

          test[:steps].each do |step|
            next unless step[:screenshot]

            # Try multiple possible paths for the screenshot
            screenshot_paths = [
              step[:screenshot],
              File.join(Dir.pwd, step[:screenshot]),
              File.join(Dir.pwd, "tmp", "capybara", step[:screenshot]),
              File.join(Dir.pwd, "tmp", "capybara", "tmp", "capydash_screenshots", File.basename(step[:screenshot]))
            ]

            actual_path = screenshot_paths.find { |path| File.exist?(path) }
            next unless actual_path

            # Copy screenshot to report directory
            filename = File.basename(step[:screenshot])
            dest_path = File.join(screenshots_dir, filename)
            FileUtils.cp(actual_path, dest_path) unless File.exist?(dest_path)
          end
        end
      end

      def generate_html(test_data, created_at)
        # Process test data into a structured format
        processed_tests = process_test_data(test_data)

        # Calculate summary statistics
        total_tests = processed_tests.sum { |test| test[:methods].length }
        passed_tests = processed_tests.sum { |test| test[:methods].count { |method| method[:status] == 'passed' } }
        failed_tests = total_tests - passed_tests

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
          # Handle different test data structures
          test_name = test[:name] || test[:test_name] || 'UnknownTest'

          # Extract actual class and method names from test name like "ApiTest#test_page_elements_are_present"
          if test_name.include?('#')
            class_name, method_name = test_name.split('#', 2)
          else
            # Fallback to old behavior if no # separator
            class_name = extract_class_name(test_name)
            method_name = extract_method_name(test_name)
          end

          tests_by_class[class_name] ||= {
            class_name: class_name,
            methods: []
          }

          # Process steps - handle different step structures
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

          # Filter out "running" steps - only show "passed" or "failed"
          processed_steps = processed_steps.reject { |step| step[:status] == 'running' }

          # Determine method status
          method_status = if processed_steps.any? { |s| s[:status] == 'failed' }
            'failed'
          elsif processed_steps.any? { |s| s[:status] == 'passed' }
            'passed'
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
        elsif test_name.start_with?('test_')
          # Extract meaningful words from test method name
          words = test_name.gsub('test_', '').split('_')
          words.map(&:capitalize).join('') + 'Test'
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

      def generate_css
        <<~CSS
          * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
          }

          body {
              font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
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

          .search-input-wrapper {
              position: relative;
              max-width: 500px;
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

          .typeahead-dropdown {
              position: absolute;
              top: 100%;
              left: 0;
              right: 0;
              background: white;
              border: 1px solid #ddd;
              border-top: none;
              border-radius: 0 0 6px 6px;
              box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
              max-height: 300px;
              overflow-y: auto;
              z-index: 1000;
              display: none;
          }

          .typeahead-suggestion {
              padding: 0.75rem 1rem;
              cursor: pointer;
              border-bottom: 1px solid #f0f0f0;
              transition: background-color 0.2s;
          }

          .typeahead-suggestion:hover,
          .typeahead-suggestion.highlighted {
              background-color: #f8f9fa;
          }

          .typeahead-suggestion:last-child {
              border-bottom: none;
          }

          .typeahead-suggestion .suggestion-text {
              font-weight: 500;
              color: #2c3e50;
          }

          .typeahead-suggestion .suggestion-category {
              font-size: 0.8rem;
              color: #666;
              margin-top: 0.25rem;
          }

          .typeahead-suggestion .suggestion-count {
              font-size: 0.75rem;
              color: #999;
              float: right;
              margin-top: 0.25rem;
          }

          .search-stats {
              margin-top: 0.5rem;
              font-size: 0.85rem;
              color: #666;
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

          .expand-toggle {
              background: none;
              border: none;
              cursor: pointer;
              padding: 0.5rem;
              border-radius: 4px;
              transition: background-color 0.2s;
              display: flex;
              align-items: center;
              justify-content: center;
          }

          .expand-toggle:hover {
              background-color: #f0f0f0;
          }

          .expand-icon {
              font-size: 0.8rem;
              color: #666;
              transition: transform 0.2s;
          }

          .expand-toggle.collapsed .expand-icon {
              transform: rotate(-90deg);
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

          .step.running {
              border-color: #3498db;
              background: #f8fcff;
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

          .step.running .step-status {
              background: #3498db;
              color: white;
          }

          .step-detail {
              color: #666;
              font-size: 0.9rem;
              margin-bottom: 0.5rem;
          }

          .screenshot-toggle {
              background: #3498db;
              color: white;
              border: none;
              padding: 0.5rem 1rem;
              border-radius: 4px;
              cursor: pointer;
              font-size: 0.8rem;
              font-weight: 600;
              transition: background-color 0.2s;
          }

          .screenshot-toggle:hover {
              background: #2980b9;
          }

          .screenshot-container {
              margin-top: 1rem;
              border: 1px solid #ddd;
              border-radius: 6px;
              background: white;
              overflow: hidden;
          }

          .screenshot {
              text-align: center;
              padding: 1rem;
          }

          .screenshot img {
              max-width: 100%;
              height: auto;
              border: 1px solid #ddd;
              border-radius: 4px;
              box-shadow: 0 2px 8px rgba(0,0,0,0.1);
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

          .highlight {
              background-color: #ffeb3b;
              padding: 0.1rem 0.2rem;
              border-radius: 3px;
              font-weight: bold;
          }

          .hidden {
              display: none !important;
          }

          @media (max-width: 768px) {
              .container {
                  padding: 0.5rem;
              }

              .header {
                  padding: 1rem;
              }

              .header h1 {
                  font-size: 1.5rem;
              }

              .summary {
                  grid-template-columns: 1fr;
              }

              .test-method {
                  padding: 1rem;
              }
          }
        CSS
      end

      def generate_javascript
        <<~JS
          class CapyDashDashboard {
              constructor() {
                  this.searchInput = document.getElementById('searchInput');
                  this.searchStats = document.getElementById('searchStats');
                  this.typeaheadDropdown = document.getElementById('typeaheadDropdown');
                  this.testResults = document.querySelector('.test-results');
                  this.allTestClasses = Array.from(document.querySelectorAll('.test-class'));
                  this.allTestMethods = Array.from(document.querySelectorAll('.test-method'));
                  this.allSteps = Array.from(document.querySelectorAll('.step'));

                  this.suggestions = [];
                  this.selectedIndex = -1;
                  this.isTypeaheadVisible = false;

                  this.init();
              }

              init() {
                  this.setupSearch();
                  this.updateSearchStats();
                  this.setupScreenshotToggles();
              }

              setupSearch() {
                  if (this.searchInput) {
                      this.searchInput.addEventListener('input', (e) => {
                          this.handleSearchInput(e.target.value);
                      });

                      this.searchInput.addEventListener('keydown', (e) => {
                          this.handleKeydown(e);
                      });

                      this.searchInput.addEventListener('blur', () => {
                          setTimeout(() => this.hideTypeahead(), 150);
                      });

                      this.searchInput.addEventListener('focus', () => {
                          if (this.searchInput.value.length > 0) {
                              this.showTypeahead();
                          }
                      });
                  }
              }

              setupScreenshotToggles() {
                  // Screenshot toggles are handled by the global function
              }

              handleSearchInput(query) {
                  this.performSearch(query);

                  if (query.length >= 2) {
                      this.generateSuggestions(query);
                      this.showTypeahead();
                  } else {
                      this.hideTypeahead();
                  }
              }

              handleKeydown(e) {
                  if (!this.isTypeaheadVisible) return;

                  switch (e.key) {
                      case 'ArrowDown':
                          e.preventDefault();
                          this.selectedIndex = Math.min(this.selectedIndex + 1, this.suggestions.length - 1);
                          this.updateHighlightedSuggestion();
                          break;
                      case 'ArrowUp':
                          e.preventDefault();
                          this.selectedIndex = Math.max(this.selectedIndex - 1, -1);
                          this.updateHighlightedSuggestion();
                          break;
                      case 'Enter':
                          e.preventDefault();
                          if (this.selectedIndex >= 0) {
                              this.selectSuggestion(this.suggestions[this.selectedIndex]);
                          }
                          break;
                      case 'Escape':
                          this.hideTypeahead();
                          break;
                  }
              }

              generateSuggestions(query) {
                  const searchTerm = query.toLowerCase();
                  this.suggestions = [];

                  const suggestionsMap = new Map();

                  this.allTestClasses.forEach(testClass => {
                      const className = testClass.querySelector('h2')?.textContent || '';
                      if (className.toLowerCase().includes(searchTerm)) {
                          const key = `class:${className}`;
                          if (!suggestionsMap.has(key)) {
                              suggestionsMap.set(key, {
                                  text: className,
                                  category: 'Test Class',
                                  type: 'class',
                                  count: 1
                              });
                          }
                      }
                  });

                  this.allTestMethods.forEach(method => {
                      const methodName = method.querySelector('h3')?.textContent || '';
                      if (methodName.toLowerCase().includes(searchTerm)) {
                          const key = `method:${methodName}`;
                          if (!suggestionsMap.has(key)) {
                              suggestionsMap.set(key, {
                                  text: methodName,
                                  category: 'Test Method',
                                  type: 'method',
                                  count: 1
                              });
                          }
                      }
                  });

                  this.allSteps.forEach(step => {
                      const stepName = step.querySelector('.step-name')?.textContent || '';
                      const stepDetail = step.querySelector('.step-detail')?.textContent || '';
                      const stepStatus = step.querySelector('.step-status')?.textContent || '';

                      if (stepName.toLowerCase().includes(searchTerm)) {
                          const key = `step:${stepName}`;
                          if (!suggestionsMap.has(key)) {
                              suggestionsMap.set(key, {
                                  text: stepName,
                                  category: 'Step',
                                  type: 'step',
                                  count: 1
                              });
                          } else {
                              suggestionsMap.get(key).count++;
                          }
                      }

                      if (stepDetail.toLowerCase().includes(searchTerm)) {
                          const key = `detail:${stepDetail}`;
                          if (!suggestionsMap.has(key)) {
                              suggestionsMap.set(key, {
                                  text: stepDetail,
                                  category: 'Step Detail',
                                  type: 'detail',
                                  count: 1
                              });
                          } else {
                              suggestionsMap.get(key).count++;
                          }
                      }

                      if (stepStatus.toLowerCase().includes(searchTerm)) {
                          const key = `status:${stepStatus}`;
                          if (!suggestionsMap.has(key)) {
                              suggestionsMap.set(key, {
                                  text: stepStatus,
                                  category: 'Status',
                                  type: 'status',
                                  count: 1
                              });
                          } else {
                              suggestionsMap.get(key).count++;
                          }
                      }
                  });

                  this.suggestions = Array.from(suggestionsMap.values())
                      .sort((a, b) => {
                          const aExact = a.text.toLowerCase().startsWith(searchTerm);
                          const bExact = b.text.toLowerCase().startsWith(searchTerm);
                          if (aExact && !bExact) return -1;
                          if (!aExact && bExact) return 1;
                          return b.count - a.count;
                      })
                      .slice(0, 10);
              }

              showTypeahead() {
                  if (this.suggestions.length > 0) {
                      this.renderSuggestions();
                      this.typeaheadDropdown.style.display = 'block';
                      this.isTypeaheadVisible = true;
                      this.selectedIndex = -1;
                  }
              }

              hideTypeahead() {
                  this.typeaheadDropdown.style.display = 'none';
                  this.isTypeaheadVisible = false;
                  this.selectedIndex = -1;
              }

              renderSuggestions() {
                  this.typeaheadDropdown.innerHTML = '';

                  this.suggestions.forEach((suggestion, index) => {
                      const suggestionEl = document.createElement('div');
                      suggestionEl.className = 'typeahead-suggestion';
                      suggestionEl.innerHTML = `
                          <div class="suggestion-text">${suggestion.text}</div>
                          <div class="suggestion-category">${suggestion.category}</div>
                          ${suggestion.count > 1 ? `<div class="suggestion-count">${suggestion.count} matches</div>` : ''}
                      `;

                      suggestionEl.addEventListener('click', () => {
                          this.selectSuggestion(suggestion);
                      });

                      this.typeaheadDropdown.appendChild(suggestionEl);
                  });
              }

              updateHighlightedSuggestion() {
                  const suggestions = this.typeaheadDropdown.querySelectorAll('.typeahead-suggestion');
                  suggestions.forEach((el, index) => {
                      el.classList.toggle('highlighted', index === this.selectedIndex);
                  });
              }

              selectSuggestion(suggestion) {
                  this.searchInput.value = suggestion.text;
                  this.performSearch(suggestion.text);
                  this.hideTypeahead();
                  this.searchInput.focus();
              }

              performSearch(query) {
                  const searchTerm = query.toLowerCase().trim();

                  if (!searchTerm) {
                      this.showAllResults();
                      this.updateSearchStats();
                      return;
                  }

                  let visibleClasses = 0;
                  let visibleMethods = 0;
                  let visibleSteps = 0;

                  this.allTestClasses.forEach(testClass => {
                      const className = testClass.querySelector('h2')?.textContent.toLowerCase() || '';
                      const methods = testClass.querySelectorAll('.test-method');
                      let classVisible = false;
                      let classMethodCount = 0;
                      let classStepCount = 0;

                      methods.forEach(method => {
                          const methodName = method.querySelector('h3')?.textContent.toLowerCase() || '';
                          const steps = method.querySelectorAll('.step');
                          let methodVisible = false;
                          let methodStepCount = 0;

                          steps.forEach(step => {
                              const stepName = step.querySelector('.step-name')?.textContent.toLowerCase() || '';
                              const stepStatus = step.querySelector('.step-status')?.textContent.toLowerCase() || '';
                              const stepDetail = step.querySelector('.step-detail')?.textContent.toLowerCase() || '';
                              const stepError = step.querySelector('.error-log pre')?.textContent.toLowerCase() || '';

                              const matches = stepName.includes(searchTerm) ||
                                            stepStatus.includes(searchTerm) ||
                                            stepDetail.includes(searchTerm) ||
                                            stepError.includes(searchTerm);

                              if (matches) {
                                  step.classList.remove('hidden');
                                  methodStepCount++;
                                  methodVisible = true;
                                  this.highlightText(step, searchTerm);
                              } else {
                                  step.classList.add('hidden');
                              }
                          });

                          if (methodVisible || methodName.includes(searchTerm)) {
                              method.classList.remove('hidden');
                              classMethodCount++;
                              classVisible = true;
                              classStepCount += methodStepCount;
                              this.highlightText(method, searchTerm);
                          } else {
                              method.classList.add('hidden');
                          }
                      });

                      if (classVisible || className.includes(searchTerm)) {
                          testClass.classList.remove('hidden');
                          visibleClasses++;
                          visibleMethods += classMethodCount;
                          visibleSteps += classStepCount;
                          this.highlightText(testClass, searchTerm);
                      } else {
                          testClass.classList.add('hidden');
                      }
                  });

                  this.updateSearchStats(visibleClasses, visibleMethods, visibleSteps);
              }

              showAllResults() {
                  this.allTestClasses.forEach(testClass => {
                      testClass.classList.remove('hidden');
                      const methods = testClass.querySelectorAll('.test-method');
                      methods.forEach(method => {
                          method.classList.remove('hidden');
                          const steps = method.querySelectorAll('.step');
                          steps.forEach(step => {
                              step.classList.remove('hidden');
                          });
                      });
                  });
              }

              highlightText(element, searchTerm) {
                  const walker = document.createTreeWalker(
                      element,
                      NodeFilter.SHOW_TEXT,
                      null,
                      false
                  );

                  const textNodes = [];
                  let node;
                  while (node = walker.nextNode()) {
                      textNodes.push(node);
                  }

                  textNodes.forEach(textNode => {
                      const parent = textNode.parentNode;
                      if (parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE') {
                          return;
                      }

                      const text = textNode.textContent;
                      const regex = new RegExp(`(${searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');

                      if (regex.test(text)) {
                          const highlightedText = text.replace(regex, '<span class="highlight">$1</span>');
                          const wrapper = document.createElement('span');
                          wrapper.innerHTML = highlightedText;
                          parent.replaceChild(wrapper, textNode);
                      }
                  });
              }

              updateSearchStats(visibleClasses = null, visibleMethods = null, visibleSteps = null) {
                  if (this.searchStats && visibleClasses === null) {
                      this.searchStats.textContent = '';
                      return;
                  }

                  if (this.searchStats) {
                      const totalClasses = this.allTestClasses.length;
                      const totalMethods = this.allTestMethods.length;
                      const totalSteps = this.allSteps.length;

                      this.searchStats.innerHTML = `
                          Showing ${visibleClasses} of ${totalClasses} test classes
                          • ${visibleMethods} of ${totalMethods} tests
                          • ${visibleSteps} of ${totalSteps} steps
                      `;
                  }
              }
          }

          function toggleScreenshot(screenshotId) {
              const container = document.getElementById(`screenshot-${screenshotId}`);
              const button = document.querySelector(`[onclick*="${screenshotId}"]`);

              if (container && button) {
                  const isHidden = container.style.display === 'none' || container.style.display === '';

                  if (isHidden) {
                      container.style.display = 'block';
                      button.textContent = '📸 Hide Screenshot';
                      button.style.background = '#e74c3c';
                  } else {
                      container.style.display = 'none';
                      button.textContent = '📸 Screenshot';
                      button.style.background = '#3498db';
                  }
              }
          }

          function toggleTestMethod(methodName) {
              const stepsContainer = document.getElementById(`steps-${methodName}`);
              const button = document.querySelector(`[onclick*="toggleTestMethod('${methodName}')"]`);
              const icon = button.querySelector('.expand-icon');

              if (stepsContainer && button && icon) {
                  const isCollapsed = stepsContainer.classList.contains('collapsed');

                  if (isCollapsed) {
                      // Expand
                      stepsContainer.classList.remove('collapsed');
                      button.classList.remove('collapsed');
                      icon.textContent = '▼';
                  } else {
                      // Collapse
                      stepsContainer.classList.add('collapsed');
                      button.classList.add('collapsed');
                      icon.textContent = '▶';
                  }
              }
          }

          document.addEventListener('DOMContentLoaded', () => {
              new CapyDashDashboard();
          });
        JS
      end
    end
  end
end
