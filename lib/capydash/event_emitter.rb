require 'capydash/dashboard_server'
require 'capydash/forwarder'

module CapyDash
  module EventEmitter
    @clients = []

    class << self
      attr_accessor :clients

      def subscribe(&block)
        @on_event = block
      end

      def broadcast(event)
        @on_event&.call(event)

        port = CapyDash.configuration&.port
        if ENV["CAPYDASH_EXTERNAL_WS"] == "1"
          forwarder = CapyDash::Forwarder.instance(port: port)
          forwarder.send_message(event)
        else
          server = CapyDash::DashboardServer.instance(port: port)
          server.broadcast(event.to_json)
        end
      end
    end
  end
end
