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

## Quick Setup

### One-Command Installation

After adding CapyDash to your Gemfile and running `bundle install`, simply run:

```bash
bundle exec rails generate capydash:install
```

This will automatically:
- ✅ Create the CapyDash initializer
- ✅ Update your test helper with all necessary hooks
- ✅ Add rake tasks for report generation
- ✅ Create an example test to get you started

### Manual Setup (Alternative)

If you prefer to set up CapyDash manually, see the [Manual Setup Guide](#manual-setup) below.

## Usage

### Run Tests with CapyDash

Run your tests normally - CapyDash will automatically instrument them:

```bash
bundle exec rails test
```

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

Then open `http://localhost:4000` in your browser.

## Troubleshooting

### Common Issues

1. **"No test data found"**: Make sure you've added the test helper configuration and are running actual Capybara tests (not just unit tests).

2. **"log shifting failed" error**: This is a Rails logger issue, not related to CapyDash. It's harmless but you can fix it by updating your Rails version.

3. **Screenshots not working**: Make sure you're using a driver that supports screenshots (like Selenium, not rack_test).

4. **Tests not appearing in report**: Ensure your tests are using Capybara methods like `visit`, `click_button`, `fill_in`, etc.

### Example Test

Here's an example test that will work with CapyDash:

```ruby
require 'test_helper'

class HomepageTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "homepage loads with correct content" do
    visit "/"
    assert_text "Welcome"

    fill_in "Your name", with: "Alice"
    click_button "Greet"
    assert_text "Hello, Alice!"
  end
end
```

## Manual Setup

If you prefer to set up CapyDash manually instead of using the generator:

### Step 1: Create CapyDash Initializer

Create `config/initializers/capydash.rb` in your Rails project:

```ruby
require 'capydash'

# Configure CapyDash
CapyDash.configure do |config|
  config.port = 4000
  config.screenshot_path = "tmp/capydash_screenshots"
end

# Subscribe to events for test data collection
CapyDash::EventEmitter.subscribe do |event|
  # Collect test data for report generation
  CapyDash::TestDataAggregator.handle_event(event)
end
```

### Step 2: Update Test Helper

In your `test/test_helper.rb`, add the following:

```ruby
require 'capydash'

# Start test run data collection
CapyDash::TestDataCollector.start_test_run

# Hook into test execution to set current test name and manage test runs
module CapyDash
  module TestHooks
    def run(&block)
      # Set the current test name for CapyDash
      CapyDash.current_test = self.name

      # Start test run data collection if not already started
      CapyDash::TestDataAggregator.start_test_run unless CapyDash::TestDataAggregator.instance_variable_get(:@current_run)

      super
    end
  end
end

# Apply the hook to the test case
class ActiveSupport::TestCase
  prepend CapyDash::TestHooks
end

# Hook to finish test run when all tests are done
Minitest.after_run do
  CapyDash::TestDataCollector.finish_test_run
  CapyDash::TestDataAggregator.finish_test_run
end
```

### Step 3: Add Rake Tasks

Create `lib/tasks/capydash.rake` in your Rails project:

```ruby
namespace :capydash do
  desc "Generate static HTML test report"
  task :report => :environment do
    CapyDash::ReportGenerator.generate_report
  end

  desc "Start local server to view static HTML report"
  task :server => :environment do
    CapyDash::DashboardServer.start
  end
end
```

### Step 4: Configure System Tests (Optional)

If you're using system tests, make sure your `test/application_system_test_case.rb` uses a driver that supports screenshots:

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 800, 600 ]
end
```

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