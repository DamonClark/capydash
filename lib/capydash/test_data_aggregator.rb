require 'json'
require 'time'
require 'securerandom'

module CapyDash
  class TestDataAggregator
    class << self
      def start_test_run
        @current_run = {
          id: generate_run_id,
          created_at: Time.now.iso8601,
          total_tests: 0,
          passed_tests: 0,
          failed_tests: 0,
          tests: []
        }
        @current_test = nil
        @test_steps = []
      end

      def finish_test_run
        return unless @current_run

        # Save the test run data
        CapyDash.save_test_run(@current_run)

        # Clear current state
        @current_run = nil
        @current_test = nil
        @test_steps = nil
      end

      def handle_event(event)
        return unless @current_run

        case event[:step_name]
        when 'test_start'
          start_new_test(event)
        when 'test_finish'
          finish_current_test(event)
        when 'test_result'
          # This indicates the test is finished
          finish_current_test(event)
        else
          # This is a test step (visit, click_button, fill_in, etc.)
          # If we don't have a current test, start one
          start_new_test(event) unless @current_test
          add_test_step(event)
        end
      end

      private

      def start_new_test(event)
        # Extract test name from the current test context
        test_name = event[:test_name] || CapyDash.current_test || "unknown_test"

        @current_test = {
          test_name: test_name,
          steps: []
        }
        @test_steps = []

        # Add the test_start step
        add_test_step(event)
      end

      def finish_current_test(event)
        return unless @current_test

        # Add the test_finish step
        add_test_step(event)

        # Determine test status
        test_status = determine_test_status(@test_steps)

        # Update counters
        @current_run[:total_tests] += 1
        if test_status == 'passed'
          @current_run[:passed_tests] += 1
        elsif test_status == 'failed'
          @current_run[:failed_tests] += 1
        end

        # Add test to current run
        @current_run[:tests] << @current_test

        # Clear current test
        @current_test = nil
        @test_steps = nil
      end

      def add_test_step(event)
        return unless @current_test

        step = {
          step_name: event[:step_name],
          detail: event[:detail],
          status: event[:status],
          test_name: event[:test_name] || CapyDash.current_test || @current_test[:test_name]
        }

        # Add screenshot if present
        if event[:screenshot]
          step[:screenshot] = event[:screenshot]
        end

        # Add error if present
        if event[:error]
          step[:error] = event[:error]
        end

        @current_test[:steps] << step
        @test_steps << step
      end

      def determine_test_status(steps)
        return 'failed' if steps.any? { |step| step[:status] == 'failed' }
        return 'passed' if steps.any? { |step| step[:status] == 'passed' }
        'running'
      end

      def generate_run_id
        "#{Time.now.to_i}_#{SecureRandom.hex(4)}"
      end
    end
  end
end
