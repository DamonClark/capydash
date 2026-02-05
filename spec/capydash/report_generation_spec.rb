require 'spec_helper'

RSpec.describe "CapyDash::RSpec.generate_report" do
  around(:each) do |example|
    Dir.mktmpdir do |dir|
      @original_dir = Dir.pwd
      Dir.chdir(dir)
      example.run
      Dir.chdir(@original_dir)
    end
  end

  before do
    CapyDash::RSpec.start_run
  end

  def mock_example(description:, status:, group_description: "Homepage", file_path: 'spec/features/home_spec.rb', error: nil)
    exception = nil
    if error
      exception = RuntimeError.new(error)
      exception.set_backtrace(["spec/test.rb:10"])
    end

    root_group = { description: group_description, parent_example_group: nil }

    execution_result = double('execution_result',
      status: status,
      exception: exception
    )

    double('example',
      full_description: description,
      execution_result: execution_result,
      metadata: {
        file_path: file_path,
        location: "#{file_path}:10",
        example_group: root_group
      }
    )
  end

  it "generates report directory with three files" do
    CapyDash::RSpec.record_example(
      mock_example(description: "loads the page", status: :passed)
    )
    report_dir = CapyDash::RSpec.generate_report

    expect(File.exist?(File.join(report_dir, "index.html"))).to be true
    expect(File.exist?(File.join(report_dir, "assets", "dashboard.css"))).to be true
    expect(File.exist?(File.join(report_dir, "assets", "dashboard.js"))).to be true
  end

  it "includes test name in generated HTML" do
    CapyDash::RSpec.record_example(
      mock_example(description: "shows the welcome message", status: :passed)
    )
    CapyDash::RSpec.generate_report
    html = File.read(File.join("capydash_report", "index.html"))

    expect(html).to include("shows the welcome message")
  end

  it "includes error details for failed tests" do
    CapyDash::RSpec.record_example(
      mock_example(description: "fails gracefully", status: :failed, error: "expected true, got false")
    )
    CapyDash::RSpec.generate_report
    html = File.read(File.join("capydash_report", "index.html"))

    expect(html).to include("expected true, got false")
  end

  it "groups tests by describe block name" do
    CapyDash::RSpec.record_example(
      mock_example(description: "test one", status: :passed, group_description: "Auth")
    )
    CapyDash::RSpec.record_example(
      mock_example(description: "test two", status: :passed, group_description: "Auth")
    )
    CapyDash::RSpec.generate_report
    html = File.read(File.join("capydash_report", "index.html"))

    expect(html.scan("Auth").length).to be >= 1
  end

  it "returns nil when no results recorded" do
    result = CapyDash::RSpec.generate_report
    expect(result).to be_nil
  end

  it "returns nil when start_run was not called" do
    # Reset state
    CapyDash::RSpec.instance_variable_set(:@started_at, nil)
    CapyDash::RSpec.instance_variable_set(:@results, [])
    result = CapyDash::RSpec.generate_report
    expect(result).to be_nil
  end
end
