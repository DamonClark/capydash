# CapyDash

A minimal static HTML report generator for RSpec system tests. CapyDash automatically generates a clean, readable test report after your RSpec suite finishes.

## Features

- ✅ **Automatic report generation** - No configuration needed
- ✅ **RSpec system test support** - Works out of the box with `rspec-rails`
- ✅ **Clean HTML reports** - Simple, readable test results
- ✅ **Error details** - Full exception messages and backtraces
- ✅ **Zero configuration** - Just add the gem and run your tests

## Installation

Add to your Gemfile:

```ruby
gem "capydash"
gem "rspec-rails"
```

Then run:

```bash
bundle install
```

## Usage

That's it! CapyDash automatically hooks into RSpec when it detects it. Just run your tests:

```bash
bundle exec rspec
```

After your test suite completes, CapyDash will automatically generate a report at:

```
capydash_report/index.html
```

Open it in your browser to view the results.

## Example Test

Here's an example RSpec system test:

```ruby
require 'rails_helper'

RSpec.describe "Homepage", type: :system do
  it "displays the welcome message" do
    visit "/"
    expect(page).to have_content("Welcome")
  end

  it "allows user to submit a form" do
    visit "/"
    fill_in "Your name", with: "Alice"
    click_button "Greet"
    expect(page).to have_content("Hello, Alice!")
  end
end
```

## Report Features

The generated report includes:

- **Summary statistics** - Total, passed, and failed test counts
- **Test grouping** - Tests organized by spec file
- **Expandable test details** - Click to view error messages
- **Error information** - Full exception messages and backtraces
- **Clean design** - Simple, readable HTML layout

## Requirements

- Ruby 2.7+
- RSpec 3.0+
- Rails 6.0+ (for system tests)

## How It Works

1. CapyDash automatically detects when RSpec is present
2. Hooks into RSpec's `before(:suite)`, `after(:each)`, and `after(:suite)` callbacks
3. Collects test results in memory during the test run
4. Generates a static HTML report after all tests complete
5. Saves the report to `capydash_report/index.html`

## Troubleshooting

### Report not generated

- Make sure you're running RSpec tests (not Minitest)
- Ensure `rspec-rails` is in your Gemfile
- Check that tests actually ran (no early exits)

### Tests not appearing in report

- Verify you're using RSpec system tests (`type: :system`)
- Make sure the test suite completed (not interrupted)

### Report shows old results

- Delete the `capydash_report` directory and run tests again
- The report is regenerated on each test run

## Development

### Running Tests

```bash
# In a Rails app with RSpec
bundle exec rspec
```

### Building the Gem

```bash
gem build capydash.gemspec
```

### Publishing

```bash
gem push capydash-0.2.0.gem
```

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with RSpec
5. Submit a pull request

---

**Note:** CapyDash is a minimal MVP focused solely on RSpec system test reporting. It does not support Minitest, configuration DSLs, local servers, or screenshots. For a simple, zero-configuration test reporting solution, CapyDash is perfect.
