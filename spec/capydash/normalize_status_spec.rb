require 'spec_helper'

RSpec.describe "CapyDash::RSpec.normalize_status" do
  subject { CapyDash::RSpec.send(:normalize_status, input) }

  context "with symbol :passed" do
    let(:input) { :passed }
    it { is_expected.to eq('passed') }
  end

  context "with symbol :failed" do
    let(:input) { :failed }
    it { is_expected.to eq('failed') }
  end

  context "with symbol :pending" do
    let(:input) { :pending }
    it { is_expected.to eq('pending') }
  end

  context "with string 'passed'" do
    let(:input) { 'passed' }
    it { is_expected.to eq('passed') }
  end

  context "with string 'failed'" do
    let(:input) { 'failed' }
    it { is_expected.to eq('failed') }
  end

  context "with unknown symbol" do
    let(:input) { :skipped }
    it { is_expected.to eq('skipped') }
  end
end
