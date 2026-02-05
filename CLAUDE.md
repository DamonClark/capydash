# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CapyDash is a minimal static HTML report generator for RSpec and Minitest system tests. It auto-hooks into both frameworks, collects test results in memory, and generates a static HTML report at `capydash_report/`. Zero configuration required — just add the gem and run tests.

**Current version:** 0.3.0 (defined in `lib/capydash/version.rb`)

## Commands

```bash
# Run RSpec tests (also generates the CapyDash report)
bundle exec rspec

# Run Minitest system tests (also generates the CapyDash report)
bundle exec rails test:system

# Build the gem
gem build capydash.gemspec

# Publish to RubyGems
gem push capydash-<version>.gem
```

The dummy Rails app in `spec/dummy_app/` has both RSpec specs (`spec/system/`) and Minitest tests (`test/system/`).

## Architecture

The gem is intentionally small (~500 lines of production code across 6 files).

### Entry Point: `lib/capydash.rb`

Auto-detects RSpec availability and calls `CapyDash::RSpec.setup!`. If running under Rails where RSpec loads after the gem, defers setup to `Rails.application.config.after_initialize`. Minitest integration is handled via the plugin system (`lib/minitest/capydash_plugin.rb`).

### Shared Reporter: `lib/capydash/reporter.rb`

Framework-agnostic report generation logic used by both RSpec and Minitest adapters:

- **`CapyDash::ReportData`** — ERB binding helper with HTML escaping
- **`CapyDash::Reporter`** module — `start_run`, `record_result`, `generate_report`, `normalize_status`, `format_exception`, `capture_screenshot`, plus private HTML/CSS/JS generators

### RSpec Adapter: `lib/capydash/rspec.rb`

`CapyDash::RSpec` extends `CapyDash::Reporter` for class-level methods:

- **Public API:** `setup!`, `record_example(example)` (plus inherited `start_run`, `generate_report`)
- **Private:** `rspec_available?`, `extract_class_name`
- Hooks via `RSpec.configure`: `before(:suite)`, `after(:each)`, `after(:suite)`
- Status derived from `execution_result.exception` (not `.status`, which isn't set during `after(:each)`)

### Minitest Adapter: `lib/capydash/minitest.rb`

`CapyDash::Minitest::Reporter` includes `CapyDash::Reporter` as an instance of `Minitest::AbstractReporter`:

- **Reporter API:** `start`, `record(result)`, `report`, `passed?`
- Registered via Minitest plugin system (`lib/minitest/capydash_plugin.rb`)
- Uses Rails' pre-captured failure screenshots (`tmp/capybara/failures_*.png`) since the browser session is torn down before the reporter's `record` runs

### Template: `lib/capydash/templates/report.html.erb`

ERB template for the HTML report. Framework-agnostic — works identically for both RSpec and Minitest results.

### Report Output Structure

```
capydash_report/
├── index.html
└── assets/
    ├── dashboard.css
    ├── dashboard.js
    └── screenshots/
        └── 001.png (failure screenshots, cleared each run)
```

## Key Design Decisions

- **RSpec and Minitest** — both frameworks supported via shared `Reporter` module
- **No configuration DSL** — hardcoded defaults, no `CapyDash.configure` block
- **No persistence** — reports generated fresh from in-memory data each run
- **No server component** — purely static HTML output
- **Separate asset files** — CSS/JS in `lib/capydash/assets/`, loaded via `File.read`
- **Failure screenshots** — captured automatically if Capybara is available, displayed with lightbox
- **Screenshots cleared each run** — only the latest run's screenshots are kept

## Dependencies

- **Runtime:** none (works with whichever test framework is present)
- **Development:** `rspec-rails ~> 6.0`, `rails >= 6.0`
- **Standard lib only:** `time`, `fileutils`, `erb`, `cgi`, `tmpdir` (no additional gems for report generation)
