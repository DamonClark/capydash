# CapyDash

Minimal, zero-config HTML report for your RSpec and Minitest tests. Add the gem, run your tests, get a report.

![CapyDash Report](docs/capydash-demo.gif)

## Setup

Add it to your Gemfile:

```ruby
group :test do
  gem "capydash"
end
```

Run `bundle install`. That's it — no configuration needed.

## Usage

Run your tests as usual:

```bash
# RSpec
bundle exec rspec

# Minitest
bundle exec rails test
bundle exec rails test:system
```

After the suite finishes, open the generated report:

```
capydash_report/index.html
```

The report includes pass/fail counts, tests grouped by class, expandable error details with backtraces, and failure screenshots with a clickable lightbox.

## Failure Screenshots

When a test fails and Capybara with a browser driver is available, CapyDash automatically captures a screenshot and embeds it in the report. Click the thumbnail to view the full-size image.

- **RSpec** — screenshot captured during `after(:each)`, before session teardown
- **Minitest** — uses Rails' built-in failure screenshot from `tmp/capybara/`

No configuration needed. If Capybara isn't available, screenshots are silently skipped.

## Requirements

- RSpec >= 3.0 **or** Minitest >= 5.0
- Ruby 2.7+

## How It Works

CapyDash auto-detects your test framework and hooks in automatically:

- **RSpec** — registers `before(:suite)`, `after(:each)`, and `after(:suite)` callbacks via `RSpec.configure`
- **Minitest** — registers a reporter via the [Minitest plugin system](https://docs.seattlerb.org/minitest/Minitest.html) (`start`, `record`, `report`)

Results are collected in memory during the run and written as a static HTML report to `capydash_report/` when the suite completes. Each run produces a fresh report — no server, no database, no config files.

## License

MIT
