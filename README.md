# CapyDash

Minimal, zero-config HTML report for your RSpec tests. Add the gem, run your tests, get a report.

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
bundle exec rspec
```

After the suite finishes, open the generated report:

```
capydash_report/index.html
```

The report includes pass/fail counts, tests grouped by spec file, and expandable error details with backtraces.

## Requirements

- RSpec >= 3.0
- Ruby 2.7+

## How It Works

CapyDash hooks into RSpec automatically via `before(:suite)`, `after(:each)`, and `after(:suite)` callbacks. It collects results in memory during the run and writes a static HTML report to `capydash_report/` when the suite completes. No server, no database, no config files.

## License

MIT
