# CapyDash

A live dashboard for Capybara tests that provides real-time visualization of test execution with screenshots, step-by-step tracking, comprehensive error reporting, and search capabilities. Perfect for debugging test failures and understanding test behavior.

## Installation

Add to your Gemfile:

```ruby
gem "capydash"
```

Or run:

```bash
bundle add capydash
```

## Usage

1. **Start the dashboard server** in one terminal:
   ```bash
   bundle exec rake capydash:server
   ```

2. **Start the frontend** in another terminal:
   ```bash
   npx vite
   ```

3. **Open your browser** to `http://localhost:5173` to view the dashboard

4. **Run your tests** with external WebSocket:
   ```bash
   CAPYDASH_EXTERNAL_WS=1 bundle exec rails test
   ```

The dashboard will show your tests running in real-time with screenshots, detailed step information, and search functionality to filter tests by name, status, or content.

## Development

### Testing with Dummy App

The project includes a dummy Rails app for testing. To run it:

```bash
cd spec/dummy_app
bundle install
bundle exec rails test
```

### Development Setup

1. Clone the repository
2. Install dependencies: `bundle install`
3. Run the dummy app tests to verify everything works
4. Make your changes
5. Test with the dummy app

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the dummy app
5. Submit a pull request

## Publishing

Build the gem:

```bash
gem build capydash.gemspec
```

Push to RubyGems:

```bash
gem push capydash-0.1.0.gem
```