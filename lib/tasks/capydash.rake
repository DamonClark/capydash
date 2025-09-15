namespace :capydash do
  desc "Start CapyDash WebSocket server"
  task server: :environment do
    port = CapyDash.configuration&.port || 4000
    puts "[CapyDash] Starting WebSocket server on ws://localhost:#{port}"
    CapyDash::DashboardServer.instance(port: port).start

    trap("INT") { puts "\n[CapyDash] Shutting down"; exit }
    sleep
  end
end
