module CapyDash
  class ErrorHandler
    class << self
      def handle_error(error, context = {})
        log_error(error, context)
        notify_error(error, context) if should_notify?(error)
        recover_from_error(error, context)
      end

      def handle_websocket_error(error, connection = nil)
        context = {
          error_type: 'websocket',
          connection_id: connection&.id,
          error_class: error.class.name
        }
        handle_error(error, context)
      end

      def handle_test_execution_error(error, test_path = nil)
        context = {
          error_type: 'test_execution',
          test_path: test_path,
          error_class: error.class.name
        }
        handle_error(error, context)
      end

      def handle_instrumentation_error(error, method_name = nil)
        context = {
          error_type: 'instrumentation',
          method_name: method_name,
          error_class: error.class.name
        }
        handle_error(error, context)
      end

      private

      def log_error(error, context)
        Logger.error(
          "Error occurred: #{error.message}",
          context.merge(
            backtrace: error.backtrace&.first(5),
            error_class: error.class.name
          )
        )
      end

      def notify_error(error, context)
        # In a production app, this would send notifications to monitoring services
        # like Sentry, Bugsnag, or custom webhooks
        puts "🚨 CRITICAL ERROR: #{error.message}"
        puts "Context: #{context}"
      end

      def should_notify?(error)
        # Only notify for critical errors
        error.is_a?(StandardError) &&
        !error.is_a?(ArgumentError) &&
        !error.is_a?(NoMethodError)
      end

      def recover_from_error(error, context)
        case context[:error_type]
        when 'websocket'
          recover_websocket_connection
        when 'test_execution'
          recover_test_execution
        when 'instrumentation'
          recover_instrumentation
        else
          # Generic recovery
          Logger.warn("No specific recovery strategy for error type: #{context[:error_type]}")
        end
      end

      def recover_websocket_connection
        Logger.info("Attempting to recover WebSocket connection")
        # In a real implementation, this would attempt to reconnect
        # or notify the dashboard to refresh the connection
      end

      def recover_test_execution
        Logger.info("Test execution error recovered")
        # Could implement retry logic or cleanup
      end

      def recover_instrumentation
        Logger.info("Instrumentation error recovered")
        # Could disable problematic instrumentation or use fallbacks
      end
    end
  end

  # Custom error classes for better error handling
  class CapyDashError < StandardError; end
  class ConfigurationError < CapyDashError; end
  class WebSocketError < CapyDashError; end
  class TestExecutionError < CapyDashError; end
  class InstrumentationError < CapyDashError; end
end
