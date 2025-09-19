# CapyDash

A static HTML dashboard for Capybara tests that provides comprehensive test reporting with screenshots, step-by-step tracking, error reporting, and search capabilities. Perfect for debugging test failures and understanding test behavior.

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

### Generate Test Report

After running your Capybara tests, generate a static HTML report:

```bash
bundle exec rake capydash:report
```

This will create a `capydash_report/index.html` file with:
- Test steps in chronological order
- Embedded screenshots for each step
- Click-to-open/close functionality for screenshots
- Typeahead search across test names, step text, and pass/fail status
- Summary statistics

### View Report in Browser

**Option 1: Open directly in browser**
```bash
open capydash_report/index.html
```

**Option 2: Use the built-in server**
```bash
bundle exec rake capydash:server
```

Then open `http://localhost:5173` in your browser.

### Run Tests with CapyDash

Run your tests normally - CapyDash will automatically instrument them:

```bash
bundle exec rails test
```

The report will be generated in `capydash_report/index.html` after test completion.

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