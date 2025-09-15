# CapyDash

A real-time test monitoring dashboard for Rails applications that provides live visualization of test execution with screenshots, step-by-step tracking, and comprehensive error reporting.

## Features

- **Real-time Test Monitoring**: Watch tests execute live with WebSocket updates
- **Visual Test Flow**: See each test step with screenshots and detailed information
- **Hierarchical Organization**: Test classes → methods → individual steps
- **Screenshot Capture**: Automatic screenshots at each test step
- **Error Tracking**: Comprehensive error reporting and logging
- **Configurable**: YAML-based configuration system
- **Production Ready**: Built-in logging, error handling, and persistence

## Quick Start

### 1. Installation

Add to your Gemfile:

```ruby
gem 'capydash', path: '/path/to/capydash'
```

Or install from source:

```bash
git clone https://github.com/your-username/capydash.git
cd capydash
bundle install
```

### 2. Configuration

Create a configuration file at `config/capydash.yml`:

```yaml
# CapyDash Configuration
server:
  host: "localhost"
  port: 4000
  max_connections: 100

dashboard:
  title: "My Test Dashboard"
  auto_scroll: true
  show_timestamps: true

tests:
  system_tests_dir: "test/system"
  feature_tests_dir: "test/features"
  screenshot_dir: "tmp/capydash_screenshots"

logging:
  level: "info"
  file: "log/capydash.log"

security:
  enable_auth: false
  secret_key: "your-secret-key-here"
```

### 3. Setup in Rails

Add to your `test/test_helper.rb`:

```ruby
require 'capydash'

# CapyDash will automatically instrument your tests
```

### 4. Running Tests

#### Option A: Standalone Server (Recommended)

```bash
# Terminal 1: Start the dashboard server
bundle exec rake capydash:server

# Terminal 2: Run tests with external WebSocket
CAPYDASH_EXTERNAL_WS=1 bundle exec rails test
```

#### Option B: In-Process Server (Development)

```bash
# Just run your tests - CapyDash starts automatically
bundle exec rails test
```

### 5. View Dashboard

Open your browser to `http://localhost:4000` to see the live test dashboard.

## Configuration Options

### Server Configuration

```yaml
server:
  host: "localhost"              # Server host
  port: 4000                     # Server port
  websocket_path: "/websocket"   # WebSocket endpoint
  max_connections: 100           # Max concurrent connections
  message_history_limit: 1000    # Max messages to keep in memory
```

### Dashboard Configuration

```yaml
dashboard:
  title: "CapyDash Test Monitor"  # Dashboard title
  refresh_interval: 1000          # UI refresh rate (ms)
  auto_scroll: true               # Auto-scroll to latest step
  show_timestamps: true           # Show timestamps in UI
  screenshot_quality: 0.8         # Screenshot compression (0.0-1.0)
  max_screenshot_width: 1200      # Max screenshot width (px)
```

### Test Configuration

```yaml
tests:
  default_directory: "test"                    # Default test directory
  system_tests_dir: "test/system"             # System tests directory
  feature_tests_dir: "test/features"          # Feature tests directory
  controller_tests_dir: "test/controllers"    # Controller tests directory
  model_tests_dir: "test/models"              # Model tests directory
  screenshot_dir: "tmp/capydash_screenshots"  # Screenshot storage
  timeout: 300                                # Test timeout (seconds)
```

### Logging Configuration

```yaml
logging:
  level: "info"           # Log level: debug, info, warn, error
  file: "log/capydash.log" # Log file path
  max_file_size: "10MB"   # Max log file size
  max_files: 5            # Number of log files to keep
```

### Security Configuration

```yaml
security:
  enable_auth: false                    # Enable authentication
  secret_key: "your-secret-key-here"   # Secret key for tokens
  session_timeout: 3600                # Session timeout (seconds)
```

## Usage

### Running Individual Test Classes

The dashboard allows you to run individual test classes by clicking the "Run" button next to each class. CapyDash automatically:

1. Detects the test class name from the test method names
2. Generates the appropriate file path (e.g., `NavigationTest` → `test/system/navigation_test.rb`)
3. Executes the test with proper environment setup

### Running All Tests

Click "Run All System Tests" to execute all system tests with live monitoring.

### Viewing Test Results

- **Test Classes**: Top-level organization by test class
- **Test Methods**: Individual test methods within each class
- **Test Steps**: Detailed step-by-step execution with screenshots
- **Status Indicators**: Visual status for each level (PASSED/FAILED/RUNNING)
- **Error Details**: Comprehensive error information for failed tests

## Development

### Project Structure

```
lib/capydash/
├── engine.rb              # Rails engine integration
├── instrumentation.rb     # Capybara method instrumentation
├── dashboard_server.rb    # WebSocket server
├── event_emitter.rb       # Event broadcasting
├── forwarder.rb          # External WebSocket forwarding
├── configuration.rb      # Configuration management
├── logger.rb             # Logging system
├── error_handler.rb      # Error handling
├── persistence.rb        # Data persistence
└── auth.rb              # Authentication

dashboard/
├── src/
│   └── App.jsx          # React dashboard
└── public/              # Static assets

config/
└── capydash.yml         # Configuration file
```

### Adding New Features

1. **Configuration**: Add new options to `Configuration` class
2. **Logging**: Use `CapyDash::Logger` for all logging
3. **Error Handling**: Use `CapyDash::ErrorHandler` for error management
4. **Persistence**: Use `CapyDash::Persistence` for data storage

### Testing

```bash
# Run the dummy app tests
cd spec/dummy_app
bundle exec rails test

# Run with CapyDash monitoring
CAPYDASH_EXTERNAL_WS=1 bundle exec rails test
```

## Troubleshooting

### Common Issues

1. **WebSocket Connection Failed**
   - Check if port 4000 is available
   - Verify firewall settings
   - Check server logs for errors

2. **Tests Not Appearing**
   - Ensure `CAPYDASH_EXTERNAL_WS=1` is set
   - Check that tests are in the correct directories
   - Verify test class naming conventions

3. **Screenshots Not Capturing**
   - Check screenshot directory permissions
   - Verify Capybara configuration
   - Check available disk space

### Debug Mode

Enable debug logging:

```yaml
logging:
  level: "debug"
```

### Logs

Check logs at:
- `log/capydash.log` - Application logs
- `tmp/capydash_screenshots/` - Screenshot storage
- `tmp/capydash_data/` - Test run persistence

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

- GitHub Issues: [Report bugs and request features](https://github.com/your-username/capydash/issues)
- Documentation: [Full documentation](https://github.com/your-username/capydash/wiki)
- Examples: [Example configurations and usage](https://github.com/your-username/capydash/examples)
