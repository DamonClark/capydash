require 'capydash/event_emitter'

module CapyDash
  class TestDataCollector
    class << self
      def start_test_run
        @test_run_started = true
        @test_count = 0
        @passed_count = 0
        @failed_count = 0
      end

      def finish_test_run
        return unless @test_run_started

        @test_run_started = false
      end

      def start_test(test_name, test_class, test_method)
        return unless @test_run_started

        @test_count += 1

        # Emit test start event
        CapyDash::EventEmitter.broadcast(
          step_name: "test_start",
          detail: "Starting test: #{test_name}",
          test_name: test_name,
          status: "running"
        )
      end

      def finish_test(test_name, status, error_message = nil)
        return unless @test_run_started

        if status == "passed"
          @passed_count += 1
        elsif status == "failed"
          @failed_count += 1
        end

        # Emit test finish event
        event_data = {
          step_name: "test_finish",
          detail: "Test #{status}: #{test_name}",
          test_name: test_name,
          status: status
        }

        if error_message
          event_data[:error] = error_message
        end

        CapyDash::EventEmitter.broadcast(event_data)
      end
    end
  end
end
