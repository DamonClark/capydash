require 'ostruct'
require "capydash/version"
require "capydash/engine"
require "capydash/instrumentation"
require "capydash/event_emitter"
require "capydash/dashboard_server"
require "capydash/configuration"
require "capydash/logger"
require "capydash/error_handler"
require "capydash/persistence"
require "capydash/auth"
require "capydash/test_data_collector"
require "capydash/test_data_aggregator"
require "capydash/report_generator"

module CapyDash
  class << self
    attr_accessor :configuration, :current_test, :config

    def configure
      self.configuration ||= OpenStruct.new
      yield(configuration)
    end

    def config
      @config ||= Configuration.load_from_file
    end

    def config=(new_config)
      @config = new_config
    end

    # Convenience methods for common operations
    def log_info(message, context = {})
      Logger.info(message, context)
    end

    def log_error(message, context = {})
      Logger.error(message, context)
    end

    def handle_error(error, context = {})
      ErrorHandler.handle_error(error, context)
    end

    def save_test_run(data)
      Persistence.save_test_run(data)
    end

    def load_test_run(run_id)
      Persistence.load_test_run(run_id)
    end

    def list_test_runs(limit = 50)
      Persistence.list_test_runs(limit)
    end
  end
end
