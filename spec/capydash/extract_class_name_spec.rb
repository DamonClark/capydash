require 'spec_helper'

RSpec.describe "CapyDash::RSpec.extract_class_name" do
  def mock_example(root_description:, file_path: 'spec/features/test_spec.rb')
    group = { description: root_description, parent_example_group: nil }
    double('example', metadata: { example_group: group, file_path: file_path })
  end

  it "returns the root describe block description" do
    example = mock_example(root_description: "Homepage")
    result = CapyDash::RSpec.send(:extract_class_name, example)
    expect(result).to eq("Homepage")
  end

  it "walks up nested groups to find root" do
    root = { description: "User Login", parent_example_group: nil }
    child = { description: "when valid", parent_example_group: root }
    example = double('example', metadata: {
      example_group: child,
      file_path: 'spec/features/login_spec.rb'
    })
    result = CapyDash::RSpec.send(:extract_class_name, example)
    expect(result).to eq("User Login")
  end

  it "falls back to file-based name when description is empty" do
    example = mock_example(root_description: "", file_path: 'spec/features/user_login_spec.rb')
    result = CapyDash::RSpec.send(:extract_class_name, example)
    expect(result).to eq("UserLoginSpec")
  end

  it "falls back to file-based name when description is nil" do
    example = mock_example(root_description: nil, file_path: 'spec/features/home_spec.rb')
    result = CapyDash::RSpec.send(:extract_class_name, example)
    expect(result).to eq("HomeSpec")
  end

  it "returns UnknownSpec when both description and file_path are empty" do
    example = mock_example(root_description: "", file_path: "")
    result = CapyDash::RSpec.send(:extract_class_name, example)
    expect(result).to eq("UnknownSpec")
  end
end
