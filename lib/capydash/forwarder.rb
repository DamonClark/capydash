require 'eventmachine'
require 'faye/websocket'
require 'json'

module CapyDash
  # Forwards events to an external WebSocket server when CAPYDASH_EXTERNAL_WS=1
  class Forwarder
    attr_reader :port

    def self.instance(port: nil)
      configured_port = port || (CapyDash.respond_to?(:configuration) ? CapyDash.configuration&.port : nil)
      @instance ||= new(port: configured_port || 4000)
    end

    def initialize(port: 4000)
      @port = port
      @connected = false
      @queue = []
      @ws = nil
      @mutex = Mutex.new
      start
    end

    def start
      return if @started
      @started = true

      Thread.new do
        EM.run do
          connect
        end
      end
    end

    def connect
      url = "ws://127.0.0.1:#{@port}"
      @ws = Faye::WebSocket::Client.new(url)

      @ws.on(:open) do |_event|
        @connected = true
        flush_queue
      end

      @ws.on(:close) do |_event|
        @connected = false
        # attempt reconnect after short delay
        EM.add_timer(0.5) { connect }
      end

      @ws.on(:error) do |event|
        # keep trying; errors are expected if server not yet up
      end
    end

    def send_message(raw_message)
      message = raw_message.is_a?(String) ? raw_message : JSON.dump(raw_message)
      @mutex.synchronize do
        if @connected && @ws
          @ws.send(message)
        else
          @queue << message
        end
      end
    end

    private

    def flush_queue
      return unless @connected && @ws
      pending = nil
      @mutex.synchronize do
        pending = @queue.dup
        @queue.clear
      end
      pending.each { |m| @ws.send(m) }
    end
  end
end
