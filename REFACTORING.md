# CapyDash MVP Refactoring

## Overview

CapyDash has been refactored into a minimal MVP that **only supports RSpec system tests**. All Minitest, Rails Engine, server, and configuration code has been removed.

## File Structure

### Kept Files
- `lib/capydash.rb` - Simple entry point that auto-loads RSpec integration
- `lib/capydash/rspec.rb` - Complete RSpec integration (all functionality inlined)
- `lib/capydash/version.rb` - Version constant
- `lib/capydash/templates/report.html.erb` - Simplified HTML template

### Deleted Files

#### Rails Engine (`engine.rb`)
**Why deleted:** No Rails Engine needed. RSpec integration works without Rails-specific initialization.

#### Instrumentation (`instrumentation.rb`)
**Why deleted:** Capybara instrumentation was for Minitest. RSpec handles test execution natively.

#### Event Emitter (`event_emitter.rb`)
**Why deleted:** Complex event system unnecessary. RSpec hooks directly call methods.

#### Dashboard Server (`dashboard_server.rb`)
**Why deleted:** No local server needed. Reports are static HTML files.

#### Configuration (`configuration.rb`)
**Why deleted:** No configuration DSL needed. MVP has sensible defaults.

#### Logger (`logger.rb`)
**Why deleted:** No logging system needed. Errors are shown in the report.

#### Error Handler (`error_handler.rb`)
**Why deleted:** Over-engineered. Simple exception formatting is sufficient.

#### Auth (`auth.rb`)
**Why deleted:** No authentication needed for static reports.

#### Forwarder (`forwarder.rb`)
**Why deleted:** Not used in RSpec integration.

#### Test Data Collector (`test_data_collector.rb`)
**Why deleted:** Minitest-specific. RSpec has native hooks.

#### Test Data Aggregator (`test_data_aggregator.rb`)
**Why deleted:** Complex file-based state management unnecessary. Simple in-memory array is sufficient.

#### Persistence (`persistence.rb`)
**Why deleted:** No need to persist test runs to disk. Reports are generated directly from in-memory data.

#### Report Generator (`report_generator.rb`)
**Why deleted:** 1000+ lines of code collapsed into ~200 lines in `rspec.rb`. All functionality inlined.

## Simplifications

### Time Handling
- **Before:** Complex ISO8601 string conversion, Time parsing
- **After:** Use `Time.now` directly, pass Time objects to template

### Metadata Usage
- **Before:** Complex test name parsing, class extraction, step tracking
- **After:** Direct RSpec metadata access, simple grouping by file path

### Data Structure
- **Before:** Nested hash structures matching Minitest format
- **After:** Simple array of results, grouped by class name

### Template
- **Before:** Complex search, typeahead, screenshot support
- **After:** Simple expand/collapse, error display only

## API Changes

### Before
```ruby
require "capydash"
# Auto-loads everything, complex initialization
```

### After
```ruby
require "capydash/rspec"
# Or simply:
require "capydash"  # Auto-detects RSpec and loads integration
```

## Usage

1. Add to Gemfile:
```ruby
gem "capydash"
gem "rspec-rails"
```

2. Run tests:
```bash
bundle exec rspec
```

3. Report generated at: `capydash_report/index.html`

## Code Reduction

- **Before:** ~15 files, ~3000+ lines
- **After:** 4 files, ~400 lines
- **Reduction:** ~87% less code

## Principles Applied

1. **Single Responsibility:** Only generates static HTML reports after RSpec
2. **Prefer Deletion:** Removed all unused abstractions
3. **Explicit over Clever:** Direct RSpec API usage, no magic
4. **No Configuration:** Sensible defaults, no DSL
5. **No Persistence:** Generate reports directly from test results

