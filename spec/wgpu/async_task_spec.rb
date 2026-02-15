# frozen_string_literal: true

RSpec.describe WGPU::AsyncTask do
  describe "#value" do
    it "returns block value" do
      task = described_class.new { 42 }
      expect(task.value).to eq(42)
    end

    it "re-raises task error" do
      task = described_class.new { raise "boom" }
      expect { task.value }.to raise_error(RuntimeError, "boom")
    end
  end
end
