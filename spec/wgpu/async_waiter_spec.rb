# frozen_string_literal: true

RSpec.describe WGPU::AsyncWaiter, :skip_gpu_check do
  it "returns immediately for a completed operation" do
    expect(described_class.wait(status_holder: { done: true }, timeout: 0)).to be_nil
  end

  it "raises WGPU::TimeoutError for an operation that does not complete" do
    expect do
      described_class.wait(status_holder: { done: false }, timeout: 0)
    end.to raise_error(WGPU::TimeoutError, /timed out after 0.0 seconds/)
  end

  it "allows the polling interval to be configured" do
    original = described_class.poll_interval
    described_class.poll_interval = 0.002

    expect(described_class.poll_interval).to eq(0.002)
    expect { described_class.poll_interval = 0 }.to raise_error(ArgumentError, /must be positive/)
  ensure
    described_class.poll_interval = original
  end
end
