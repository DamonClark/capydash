require 'json'
require 'time'
require 'securerandom'
require 'fileutils'

module CapyDash
  class TestDataAggregator
    class << self
      def start_test_run
        # Don't start a new run if one is already in progress
        return if test_run_started?

        run_id = generate_run_id
        run_data = {
          id: run_id,
          created_at: Time.now.iso8601,
          total_tests: 0,
          passed_tests: 0,
          failed_tests: 0,
          tests: []
        }

        # Save initial run data to file
        save_run_data(run_data)

        # Set current test context
        set_current_test_context(run_id, nil, [])
      end

      def test_run_started?
        get_current_run_id != nil
      end

      def finish_test_run
        run_id = get_current_run_id
        return unless run_id

        # Load current run data
        run_data = load_run_data(run_id)
        return unless run_data

        # Save the final test run data
        CapyDash.save_test_run(run_data)

        # Clear current state
        clear_current_test_context
      end

      def handle_event(event)
        run_id = get_current_run_id
        return unless run_id

        # Load current run data
        run_data = load_run_data(run_id)
        return unless run_data

        case event[:step_name]
        when 'test_start'
          start_new_test(event, run_data)
        when 'test_finish'
          finish_current_test(event, run_data)
        when 'test_result'
          # This indicates the test is finished
          finish_current_test(event, run_data)
        else
          # This is a test step (visit, click_button, fill_in, etc.)
          # If we don't have a current test, start one
          current_test = get_current_test
          start_new_test(event, run_data) unless current_test
          add_test_step(event, run_data)
        end
      end

      private

      def start_new_test(event, run_data)
        # Extract test name from the current test context
        test_name = event[:test_name] || CapyDash.current_test || "unknown_test"

        current_test = {
          test_name: test_name,
          steps: []
        }

        # Set current test context
        set_current_test_context(run_data[:id], current_test, [])

        # Add the test_start step
        add_test_step(event, run_data)
      end

      def finish_current_test(event, run_data)
        current_test = get_current_test
        return unless current_test

        # Add the test_finish step
        add_test_step(event, run_data)

        # Get updated test data
        current_test = get_current_test
        test_steps = get_current_test_steps

        # Determine test status
        test_status = determine_test_status(test_steps)

        # Update counters
        run_data[:total_tests] += 1
        if test_status == 'passed'
          run_data[:passed_tests] += 1
        elsif test_status == 'failed'
          run_data[:failed_tests] += 1
        end

        # Add test to current run
        run_data[:tests] << current_test

        # Save updated run data
        save_run_data(run_data)

        # Clear current test
        set_current_test_context(run_data[:id], nil, [])
      end

      def add_test_step(event, run_data)
        current_test = get_current_test
        return unless current_test

        step = {
          step_name: event[:step_name],
          detail: event[:detail],
          status: event[:status],
          test_name: event[:test_name] || CapyDash.current_test || current_test[:test_name]
        }

        # Add screenshot if present
        if event[:screenshot]
          step[:screenshot] = event[:screenshot]
        end

        # Add error if present
        if event[:error]
          step[:error] = event[:error]
        end

        # Update current test with new step
        current_test[:steps] << step
        test_steps = get_current_test_steps + [step]

        # Save updated test context
        set_current_test_context(run_data[:id], current_test, test_steps)
      end

      def determine_test_status(steps)
        return 'failed' if steps.any? { |step| step[:status] == 'failed' }
        return 'passed' if steps.any? { |step| step[:status] == 'passed' }
        'running'
      end

      def generate_run_id
        "#{Time.now.to_i}_#{SecureRandom.hex(4)}"
      end

      # File-based storage methods for parallel testing support
      def run_data_file(run_id)
        File.join(Dir.pwd, "tmp", "capydash_data", "run_#{run_id}.json")
      end

      def context_file
        File.join(Dir.pwd, "tmp", "capydash_data", "current_context.json")
      end

      def save_run_data(run_data)
        FileUtils.mkdir_p(File.dirname(run_data_file(run_data[:id])))
        File.write(run_data_file(run_data[:id]), run_data.to_json)
      end

      def load_run_data(run_id)
        file_path = run_data_file(run_id)
        return nil unless File.exist?(file_path)

        JSON.parse(File.read(file_path), symbolize_names: true)
      end

      def set_current_test_context(run_id, current_test, test_steps)
        context = {
          run_id: run_id,
          current_test: current_test,
          test_steps: test_steps
        }

        FileUtils.mkdir_p(File.dirname(context_file))
        File.write(context_file, context.to_json)
      end

      def get_current_run_id
        return nil unless File.exist?(context_file)

        context = JSON.parse(File.read(context_file), symbolize_names: true)
        context[:run_id]
      end

      def get_current_test
        return nil unless File.exist?(context_file)

        context = JSON.parse(File.read(context_file), symbolize_names: true)
        context[:current_test]
      end

      def get_current_test_steps
        return [] unless File.exist?(context_file)

        context = JSON.parse(File.read(context_file), symbolize_names: true)
        context[:test_steps] || []
      end

      def clear_current_test_context
        File.delete(context_file) if File.exist?(context_file)
      end
    end
  end
end
