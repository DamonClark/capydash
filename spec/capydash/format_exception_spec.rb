require 'spec_helper'

RSpec.describe "CapyDash::RSpec.format_exception" do
  it "returns nil for nil input" do
    result = CapyDash::RSpec.send(:format_exception, nil)
    expect(result).to be_nil
  end

  it "formats exception class and message" do
    error = RuntimeError.new("something broke")
    error.set_backtrace([])
    result = CapyDash::RSpec.send(:format_exception, error)
    expect(result).to eq("RuntimeError: something broke")
  end

  it "includes first 5 backtrace lines" do
    error = RuntimeError.new("fail")
    error.set_backtrace(["line1", "line2", "line3", "line4", "line5", "line6"])
    result = CapyDash::RSpec.send(:format_exception, error)
    expect(result).to include("  line1")
    expect(result).to include("  line5")
    expect(result).not_to include("line6")
  end

  it "handles exception with no backtrace" do
    error = RuntimeError.new("no trace")
    error.set_backtrace(nil)
    result = CapyDash::RSpec.send(:format_exception, error)
    expect(result).to eq("RuntimeError: no trace")
  end
end
