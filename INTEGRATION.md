# CapyDash RSpec Integration Guide

## Changes Made

### 1. Fixed Method Visibility
- **Issue**: `start_run`, `record_example`, and `generate_report` were private methods but called from RSpec hooks
- **Fix**: Moved these methods to be public (before the `private` keyword)
- These methods are now safely callable from RSpec's `before(:suite)`, `after(:each)`, and `after(:suite)` hooks

### 2. Improved Status Tracking
- **Added**: `normalize_status` method to properly convert RSpec status symbols to strings
- **Handles**: `:passed`, `:failed`, `:pending`, and other status types
- **Result**: Each example's pass/fail status is correctly recorded and displayed

### 3. Search Functionality
- **Added**: Search bar in the HTML report header
- **Features**:
  - Filter by test name (partial match, case-insensitive)
  - Filter by status (type "pass", "fail", "passed", "failed", or "pending")
  - Real-time filtering as you type
  - Automatically hides test classes when all their tests are filtered out

## Code Structure

### Public Methods (Callable from RSpec hooks)
- `start_run` - Initializes test run tracking
- `record_example(example)` - Records each test example with its status
- `generate_report` - Generates the HTML report after suite completes
- `setup!` - Configures RSpec hooks (called automatically)

### Private Methods (Internal helpers)
- `normalize_status` - Normalizes RSpec status symbols to strings
- `extract_class_name` - Extracts class name from file path
- `format_exception` - Formats exception messages and backtraces
- `generate_html`, `generate_css`, `generate_javascript` - Report generation helpers

## Integration with RSpec Rails

### Step 1: Add to Gemfile

```ruby
gem "capydash"
gem "rspec-rails"
```

Then run:
```bash
bundle install
```

### Step 2: No Configuration Needed!

CapyDash automatically:
1. Detects when RSpec is present
2. Hooks into RSpec's configuration
3. Sets up `before(:suite)`, `after(:each)`, and `after(:suite)` hooks
4. Generates the report automatically after tests complete

### Step 3: Run Your Tests

```bash
bundle exec rspec
```

### Step 4: View Report

After tests complete, open:
```
capydash_report/index.html
```

The report includes:
- Summary statistics (total, passed, failed)
- Each test with pass/fail status badge
- Search bar for filtering
- Expandable test details with error messages

## Example RSpec Test

```ruby
# spec/system/homepage_spec.rb
require 'rails_helper'

RSpec.describe "Homepage", type: :system do
  it "displays the welcome message" do
    visit "/"
    expect(page).to have_content("Welcome")
  end

  it "handles form submission" do
    visit "/"
    fill_in "Name", with: "Alice"
    click_button "Submit"
    expect(page).to have_content("Hello, Alice")
  end
end
```

## How It Works

1. **Before Suite**: `start_run` initializes tracking
2. **After Each Example**: `record_example` captures:
   - Test name (`example.full_description`)
   - Status (passed/failed/pending)
   - Error message (if failed)
   - File path and location
3. **After Suite**: `generate_report`:
   - Groups tests by spec file
   - Calculates statistics
   - Generates HTML, CSS, and JavaScript
   - Saves to `capydash_report/` directory

## Status Tracking

CapyDash correctly tracks:
- ✅ **Passed** - Tests that completed successfully
- ❌ **Failed** - Tests that raised exceptions or failed assertions
- ⏸️ **Pending** - Tests marked as pending or skipped

Status is displayed as a colored badge next to each test name in the report.

## Search Features

The search bar supports:
- **Name search**: Type any part of a test name (e.g., "homepage", "form")
- **Status filter**: Type "pass", "fail", "passed", "failed", or "pending"
- **Combined**: Search works in real-time as you type

Example searches:
- `"pass"` → Shows only passed tests
- `"fail"` → Shows only failed tests
- `"homepage"` → Shows tests with "homepage" in the name

## Requirements

- Ruby 2.7+
- RSpec 3.0+
- Rails 6.0+ (for system tests)

## Troubleshooting

**Report not generated?**
- Ensure tests actually ran (no early exits)
- Check that `capydash_report/` directory was created
- Verify RSpec hooks are being called

**Status not showing correctly?**
- Ensure you're using RSpec system tests (`type: :system`)
- Check that examples are completing (not skipped)

**Search not working?**
- Ensure JavaScript is enabled in your browser
- Check browser console for errors
- Verify `assets/dashboard.js` was generated



