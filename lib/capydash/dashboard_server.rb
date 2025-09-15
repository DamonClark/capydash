require 'eventmachine'
require 'em-websocket'

module CapyDash
  class DashboardServer
    attr_reader :port, :clients

    # Provide a single shared instance for the whole process
    def self.instance(port: nil)
      configured_port = port || CapyDash.config.server_port
      @instance ||= new(port: configured_port)
    end

    def initialize(port: nil)
      @port = port || CapyDash.config.server_port
      @clients = []
      @history = [] # recent events to replay on reconnect
      @history_limit = CapyDash.config.message_history_limit
      @max_connections = CapyDash.config.max_connections
    end

    # Start the WebSocket server in a background thread
    def start
      return if defined?(@started) && @started
      @started = true
      Thread.new do
        EM.run do
          EM::WebSocket.run(host: "0.0.0.0", port: @port) do |ws|

            ws.onopen do
              begin
                # Check connection limit
                if @clients.length >= @max_connections
                  CapyDash::Logger.warn("Connection limit reached", {
                    current_connections: @clients.length,
                    max_connections: @max_connections
                  })
                  ws.close
                  return
                end

                @clients << ws
                CapyDash::Logger.info("Client connected", {
                  total_clients: @clients.length,
                  client_id: ws.object_id
                })
                puts "Client connected"

                # Replay recent history so refreshed clients see last events
                @history.each do |msg|
                  begin
                    ws.send(msg)
                  rescue => e
                    CapyDash::ErrorHandler.handle_websocket_error(e, ws)
                  end
                end
              rescue => e
                CapyDash::ErrorHandler.handle_websocket_error(e, ws)
              end
            end

            ws.onclose do
              begin
                @clients.delete(ws)
                CapyDash::Logger.info("Client disconnected", {
                  remaining_clients: @clients.length,
                  client_id: ws.object_id
                })
                puts "Client disconnected"
              rescue => e
                CapyDash::ErrorHandler.handle_websocket_error(e, ws)
              end
            end

            ws.onmessage do |msg|
              begin
                CapyDash::Logger.debug("Received WebSocket message", {
                  message_length: msg.length,
                  client_id: ws.object_id
                })
                puts "Received message: #{msg}"

                data = JSON.parse(msg) rescue nil
                if data && data["command"] == "run_tests"
                  args = data["args"] || ["bundle", "exec", "rails", "test", "test/system"]
                  CapyDash::Logger.info("Executing test command", {
                    command: args.join(' '),
                    client_id: ws.object_id
                  })
                  puts "[CapyDash] Running command: #{args.join(' ')}"

                  Thread.new do
                    begin
                      # Change to the dummy app directory and run tests there
                      current_dir = File.dirname(__FILE__)
                      gem_root = File.expand_path(File.join(current_dir, "..", ".."))
                      dummy_app_path = File.join(gem_root, "spec", "dummy_app")

                      CapyDash::Logger.info("Running tests in directory", {
                        directory: dummy_app_path,
                        exists: Dir.exist?(dummy_app_path)
                      })
                      puts "[CapyDash] Running tests in: #{dummy_app_path}"
                      puts "[CapyDash] Directory exists: #{Dir.exist?(dummy_app_path)}"

                      Dir.chdir(dummy_app_path) do
                        # Set Rails environment and ensure CapyDash is loaded
                        ENV["RAILS_ENV"] = "test"
                        ENV["CAPYDASH_EXTERNAL_WS"] = "1"  # Use external WebSocket mode

                        puts "[CapyDash] Current directory: #{Dir.pwd}"
                        puts "[CapyDash] Running: #{args.join(' ')}"

                        # Run the command and capture both stdout and stderr
                        IO.popen(args, err: [:child, :out]) do |io|
                          io.each_line do |line|
                            puts "[CapyDash] Test output: #{line.strip}"
                            event = { type: "runner", line: line.strip, status: "running", ts: Time.now.to_i }
                            broadcast(event.to_json)
                          end
                        end
                      end
                    rescue => e
                      CapyDash::ErrorHandler.handle_test_execution_error(e, args.join(' '))
                      broadcast({ type: "runner", line: "Error: #{e.message}", status: "failed", ts: Time.now.to_i }.to_json)
                    end
                    broadcast({ type: "runner", line: "Finished", status: "passed", ts: Time.now.to_i }.to_json)
                  end
                else
                  # Optionally broadcast to all clients
                  broadcast(msg)
                end
              rescue => e
                CapyDash::ErrorHandler.handle_websocket_error(e, ws)
                warn "[CapyDash] ws.onmessage error: #{e.message}"
                puts "[CapyDash] Backtrace: #{e.backtrace.first(5).join("\n")}"
              end
            end

          end
        end
      end
    end

    # Send a message to all connected clients
    def broadcast(message)
      begin
        # store in history buffer
        @history << message
        @history.shift if @history.length > @history_limit

        # fan out to all connected clients
        @clients.each do |client|
          begin
            client.send(message)
          rescue => e
            CapyDash::ErrorHandler.handle_websocket_error(e, client)
            # Remove dead connections
            @clients.delete(client)
          end
        end
      rescue => e
        CapyDash::ErrorHandler.handle_error(e, {
          error_type: 'broadcast',
          message_length: message&.length
        })
      end
    end

    # Stop the WebSocket server gracefully
    def stop
      EM.stop_event_loop if EM.reactor_running?
    end
  end
end
