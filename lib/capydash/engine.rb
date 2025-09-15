module CapyDash
  class Engine < ::Rails::Engine
    isolate_namespace CapyDash

    rake_tasks do
      load File.expand_path("../tasks/capydash.rake", __dir__)
    end

    initializer "capydash.configuration", before: :load_config_initializers do
      # Load configuration
      CapyDash.config = CapyDash::Configuration.load_from_file
      CapyDash::Logger.setup(CapyDash.config)

      CapyDash::Logger.info("CapyDash configuration loaded", {
        server_port: CapyDash.config.server_port,
        log_level: CapyDash.config.log_level,
        auth_enabled: CapyDash.config.auth_enabled?
      })
    end

    initializer "capydash.instrumentation", after: :load_config_initializers do
      begin
        # Hook into Capybara sessions automatically
        ActiveSupport.on_load(:action_dispatch_integration_test) do
          Capybara::Session.include(CapyDash::Instrumentation)
        end

        # Start WebSocket server automatically in dev/test unless using external WS
        if (Rails.env.development? || Rails.env.test?) && ENV["CAPYDASH_EXTERNAL_WS"] != "1"
          port = CapyDash.config.server_port
          CapyDash::DashboardServer.instance(port: port).start

          CapyDash::Logger.info("WebSocket server started", {
            port: port,
            environment: Rails.env
          })
          puts "[CapyDash] WebSocket server started on ws://localhost:#{port}"
        else
          CapyDash::Logger.info("Skipping in-process WebSocket server", {
            reason: ENV["CAPYDASH_EXTERNAL_WS"] == "1" ? "external_mode" : "production_environment",
            environment: Rails.env
          })
          puts "[CapyDash] Skipping in-process WebSocket server (external mode)" if ENV["CAPYDASH_EXTERNAL_WS"] == "1"
        end
      rescue => e
        CapyDash::ErrorHandler.handle_error(e, {
          error_type: 'initialization',
          component: 'engine'
        })
        raise
      end
    end
  end
end
