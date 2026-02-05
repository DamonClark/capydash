# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CapyDash is a minimal static HTML report generator for RSpec system tests. It auto-hooks into RSpec via `before(:suite)`, `after(:each)`, and `after(:suite)` callbacks, collects test results in memory, and generates a static HTML report at `capydash_report/`. Zero configuration required — just add the gem and run tests.

**Current version:** 0.2.4 (defined in `lib/capydash/version.rb`)

## Commands

```bash
# Run tests (also generates the CapyDash report)
bundle exec rspec

# Build the gem
gem build capydash.gemspec

# Publish to RubyGems
gem push capydash-<version>.gem
```

The dummy Rails app in `spec/dummy_app/` uses Minitest (not RSpec) for its own tests.

## Architecture

The gem is intentionally small (~400 lines of production code across 4 files).

### Entry Point: `lib/capydash.rb`

Auto-detects RSpec availability and calls `CapyDash::RSpec.setup!`. If running under Rails where RSpec loads after the gem, defers setup to `Rails.application.config.after_initialize`.

### Core Module: `lib/capydash/rspec.rb`

All logic lives in `CapyDash::RSpec` as class-level methods (via `class << self`):

- **Public API:** `setup!`, `start_run`, `record_example(example)`, `generate_report`
- **Private helpers:** `normalize_status`, `extract_class_name`, `format_exception`, `generate_html`, `generate_css`, `generate_javascript`

`setup!` is idempotent (guarded by `@configured` flag). Report generation writes three files: `index.html` (from ERB template), `assets/dashboard.css`, and `assets/dashboard.js`.

### Template: `lib/capydash/templates/report.html.erb`

ERB template for the HTML report. CSS and JS are generated inline as Ruby heredocs in `rspec.rb`, not from separate asset files.

### Report Output Structure

```
capydash_report/
├── index.html
└── assets/
    ├── dashboard.css
    └── dashboard.js
```

## Key Design Decisions

- **RSpec only** — Minitest support was deliberately removed in a major refactoring
- **No configuration DSL** — hardcoded defaults, no `CapyDash.configure` block
- **No persistence** — reports generated fresh from in-memory data each run
- **No server component** — purely static HTML output
- **Inline asset generation** — CSS/JS generated as Ruby strings, not external files

## Dependencies

- **Runtime:** `rspec >= 3.0` (sole runtime dependency)
- **Development:** `rspec-rails ~> 6.0`, `rails >= 6.0`
- **Standard lib only:** `time`, `fileutils`, `erb` (no additional gems for report generation)
