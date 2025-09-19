namespace :capydash do
  desc "Start local server to view static HTML report"
  task server: :environment do
    require 'webrick'
    require 'capydash/report_generator'

    report_dir = File.join(Dir.pwd, "capydash_report")

    unless Dir.exist?(report_dir)
      puts "No report directory found. Run 'bundle exec rake capydash:report' first."
      exit 1
    end

    # Try different ports if 5173 is busy
    port = 5173
    begin
      server = WEBrick::HTTPServer.new(
        Port: port,
        DocumentRoot: report_dir,
        Logger: WEBrick::Log.new(nil, WEBrick::Log::ERROR),
        AccessLog: [],
        BindAddress: '127.0.0.1'
      )
    rescue Errno::EADDRINUSE
      port = 8080
      puts "Port 5173 is busy, trying port #{port}..."
      server = WEBrick::HTTPServer.new(
        Port: port,
        DocumentRoot: report_dir,
        Logger: WEBrick::Log.new(nil, WEBrick::Log::ERROR),
        AccessLog: [],
        BindAddress: '127.0.0.1'
      )
    end

    puts "Starting static file server on http://localhost:#{port}"
    puts "Report available at: http://localhost:#{port}/index.html"
    puts "Press Ctrl+C to stop the server"

    trap("INT") {
      puts "\nShutting down server..."
      server.shutdown
    }

    begin
      server.start
    rescue => e
      puts "Error starting server: #{e.message}"
      exit 1
    end
  end

  desc "Generate static HTML test report"
  task report: :environment do
    require 'capydash/report_generator'

    report_path = CapyDash::ReportGenerator.generate_report

    if report_path
      puts "Report generated: file://#{File.absolute_path(report_path)}"
    else
      puts "No test data found. Run some tests first to generate a report."
      exit 1
    end
  end

end
