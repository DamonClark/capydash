module CapyDash
  class Configuration
    attr_accessor :server, :dashboard, :tests, :logging, :security, :performance

    def initialize
      @server = {
        host: "localhost",
        port: 4000,
        websocket_path: "/websocket",
        max_connections: 100,
        message_history_limit: 1000
      }

      @dashboard = {
        title: "CapyDash Test Monitor",
        refresh_interval: 1000,
        auto_scroll: true,
        show_timestamps: true,
        screenshot_quality: 0.8,
        max_screenshot_width: 1200
      }

      @tests = {
        default_directory: "test",
        system_tests_dir: "test/system",
        feature_tests_dir: "test/features",
        controller_tests_dir: "test/controllers",
        model_tests_dir: "test/models",
        screenshot_dir: "tmp/capydash_screenshots",
        timeout: 300
      }

      @logging = {
        level: "info",
        file: "log/capydash.log",
        max_file_size: "10MB",
        max_files: 5
      }

      @security = {
        enable_auth: false,
        secret_key: "your-secret-key-here",
        session_timeout: 3600
      }

      @performance = {
        enable_compression: true,
        cleanup_interval: 300,
        max_memory_usage: "512MB"
      }
    end

    def self.load_from_file(config_path = nil)
      config_path ||= File.join(Dir.pwd, "config", "capydash.yml")

      if File.exist?(config_path)
        require 'yaml'
        yaml_config = YAML.load_file(config_path)

        config = new
        config.load_from_hash(yaml_config)
        config
      else
        # Return default configuration if file doesn't exist
        new
      end
    rescue => e
      puts "Warning: Could not load configuration from #{config_path}: #{e.message}"
      puts "Using default configuration."
      new
    end

    def load_from_hash(hash)
      @server.merge!(hash['server']) if hash['server']
      @dashboard.merge!(hash['dashboard']) if hash['dashboard']
      @tests.merge!(hash['tests']) if hash['tests']
      @logging.merge!(hash['logging']) if hash['logging']
      @security.merge!(hash['security']) if hash['security']
      @performance.merge!(hash['performance']) if hash['performance']
    end

    def server_host
      @server[:host]
    end

    def server_port
      @server[:port]
    end

    def websocket_path
      @server[:websocket_path]
    end

    def max_connections
      @server[:max_connections]
    end

    def message_history_limit
      @server[:message_history_limit]
    end

    def dashboard_title
      @dashboard[:title]
    end

    def auto_scroll?
      @dashboard[:auto_scroll]
    end

    def show_timestamps?
      @dashboard[:show_timestamps]
    end

    def screenshot_quality
      @dashboard[:screenshot_quality]
    end

    def max_screenshot_width
      @dashboard[:max_screenshot_width]
    end

    def system_tests_dir
      @tests[:system_tests_dir]
    end

    def feature_tests_dir
      @tests[:feature_tests_dir]
    end

    def controller_tests_dir
      @tests[:controller_tests_dir]
    end

    def model_tests_dir
      @tests[:model_tests_dir]
    end

    def screenshot_dir
      @tests[:screenshot_dir]
    end

    def test_timeout
      @tests[:timeout]
    end

    def log_level
      @logging[:level]
    end

    def log_file
      @logging[:file]
    end

    def max_files
      @logging[:max_files]
    end

    def max_file_size
      @logging[:max_file_size]
    end

    def auth_enabled?
      @security[:enable_auth]
    end

    def secret_key
      @security[:secret_key]
    end

    def session_timeout
      @security[:session_timeout]
    end

    def compression_enabled?
      @performance[:enable_compression]
    end

    def cleanup_interval
      @performance[:cleanup_interval]
    end

    def max_memory_usage
      @performance[:max_memory_usage]
    end
  end
end
