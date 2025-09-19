require 'rails/generators'

module Capydash
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Installs CapyDash with all necessary configuration files"

      def create_initializer
        create_file "config/initializers/capydash.rb", <<~RUBY
          require 'capydash'

          # Configure CapyDash
          CapyDash.configure do |config|
            config.port = 4000
            config.screenshot_path = "tmp/capydash_screenshots"
          end

          # Subscribe to events for test data collection
          CapyDash::EventEmitter.subscribe do |event|
            # Collect test data for report generation
            CapyDash::TestDataAggregator.handle_event(event)
          end
        RUBY
      end

      def create_rake_tasks
        create_file "lib/tasks/capydash.rake", <<~RUBY
          namespace :capydash do
            desc "Generate static HTML test report"
            task :report => :environment do
              CapyDash::ReportGenerator.generate_report
            end

            desc "Start local server to view static HTML report"
            task :server => :environment do
              CapyDash::DashboardServer.start
            end
          end
        RUBY
      end

      def update_test_helper
        test_helper_path = "test/test_helper.rb"

        if File.exist?(test_helper_path)
          # Read existing test helper
          content = File.read(test_helper_path)

          # Check if CapyDash is already configured
          unless content.include?("require 'capydash'")
            # Add CapyDash configuration
            capydash_config = <<~RUBY

              # CapyDash configuration
              require 'capydash'

              # Start test run data collection
              CapyDash::TestDataCollector.start_test_run

              # Hook into test execution to set current test name and manage test runs
              module CapyDash
                module TestHooks
                  def run(&block)
                    # Set the current test name for CapyDash
                    CapyDash.current_test = self.name

                    # Start test run data collection if not already started
                    CapyDash::TestDataAggregator.start_test_run unless CapyDash::TestDataAggregator.instance_variable_get(:@current_run)

                    super
                  end
                end
              end

              # Apply the hook to the test case
              class ActiveSupport::TestCase
                prepend CapyDash::TestHooks
              end

              # Hook to finish test run when all tests are done
              Minitest.after_run do
                CapyDash::TestDataCollector.finish_test_run
                CapyDash::TestDataAggregator.finish_test_run
              end
            RUBY

            # Insert after the last require statement
            if content.match(/require.*\n/)
              content = content.gsub(/(require.*\n)/, "\\1#{capydash_config}")
            else
              content = capydash_config + content
            end

            File.write(test_helper_path, content)
            say "Updated test/test_helper.rb with CapyDash configuration"
          else
            say "CapyDash already configured in test/test_helper.rb", :yellow
          end
        else
          say "test/test_helper.rb not found. Please add CapyDash configuration manually.", :red
        end
      end

      def create_example_test
        example_test_path = "test/system/capydash_example_test.rb"

        unless File.exist?(example_test_path)
          create_file example_test_path, <<~RUBY
            require "application_system_test_case"

            class CapydashExampleTest < ApplicationSystemTestCase
              test "example test for CapyDash" do
                visit "/"

                # This test will be captured by CapyDash
                assert_text "Welcome"

                # Fill in a form
                fill_in "Your name", with: "Alice" if page.has_field?("Your name")
                click_button "Submit" if page.has_button?("Submit")
              end
            end
          RUBY
          say "Created example test at #{example_test_path}"
        else
          say "Example test already exists at #{example_test_path}", :yellow
        end
      end

      def show_instructions
        say "\n" + "="*60, :green
        say "CapyDash has been successfully installed!", :green
        say "="*60, :green
        say "\nNext steps:", :yellow
        say "1. Run your tests: bundle exec rails test"
        say "2. Generate report: bundle exec rake capydash:report"
        say "3. View report: open capydash_report/index.html"
        say "\nFor more information, see the README.md file."
        say "="*60, :green
      end
    end
  end
end
