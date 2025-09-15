require 'logger'
require 'fileutils'

module CapyDash
  class Logger
    class << self
      attr_accessor :instance
    end

    def initialize(config = nil)
      @config = config || Configuration.new
      @logger = create_logger
    end

    def self.setup(config = nil)
      self.instance = new(config)
    end

    def self.info(message, context = {})
      instance&.info(message, context)
    end

    def self.warn(message, context = {})
      instance&.warn(message, context)
    end

    def self.error(message, context = {})
      instance&.error(message, context)
    end

    def self.debug(message, context = {})
      instance&.debug(message, context)
    end

    def info(message, context = {})
      log(:info, message, context)
    end

    def warn(message, context = {})
      log(:warn, message, context)
    end

    def error(message, context = {})
      log(:error, message, context)
    end

    def debug(message, context = {})
      log(:debug, message, context)
    end

    private

    def create_logger
      # Ensure log directory exists
      log_dir = File.dirname(@config.log_file)
      FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)

      # Create logger with file rotation
      logger = ::Logger.new(
        @config.log_file,
        @config.max_files,
        @config.max_file_size
      )

      # Set log level
      logger.level = case @config.log_level.downcase
                    when 'debug' then ::Logger::DEBUG
                    when 'info' then ::Logger::INFO
                    when 'warn' then ::Logger::WARN
                    when 'error' then ::Logger::ERROR
                    else ::Logger::INFO
                    end

      # Set format
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{progname}: #{msg}\n"
      end

      logger
    end

    def log(level, message, context = {})
      return unless @logger

      # Add context information
      full_message = message
      if context.any?
        context_str = context.map { |k, v| "#{k}=#{v}" }.join(' ')
        full_message = "#{message} | #{context_str}"
      end

      @logger.send(level, full_message)
    rescue => e
      # Fallback to stdout if logging fails
      puts "Logging error: #{e.message}"
      puts "#{level.upcase}: #{message}"
    end
  end
end
